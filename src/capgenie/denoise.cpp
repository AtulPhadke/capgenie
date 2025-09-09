// Created by Atul Phadke, February 12th, 2025

// Platform-specific definitions
#ifdef __linux__
    #define _GNU_SOURCE
#endif
#include <iostream>
#include <vector>
#include <thread>
#include <atomic>
#include <cstring>
#include <cstdint>
#include <pybind11/pybind11.h>
#include "platform_compat.h"

namespace py = pybind11;

#define NUM_THREADS 10  // Adjust based on CPU cores
int QUALITY_THRESHOLD = 30;  // Min average quality score to keep

std::atomic<long long> total_quality_sum(0);
std::atomic<size_t> total_chars(0);
std::atomic<size_t> low_quality_reads(0);
std::atomic<size_t> num_reads(0);
// Variables for storing read quality data



/**
 * process_chunk: const char*, size_t, size_t --> void
-- Processes a chunk of FASTQ data and calculates quality statistics
 * @param [in] data (const char*) - Memory-mapped file data
 * @param [in] start (size_t) - Starting position in the data
 * @param [in] end (size_t) - Ending position in the data
 * @param [out] None - Updates global quality statistics
** Processes FASTQ chunk and calculates quality metrics
*/
void process_chunk(const char* data, size_t start, size_t end) {
    size_t i = start;
    std::string high_quality_reads = "";

    while (i < end) {
        // Read FASTQ entry
        std::string id_line, seq_line, plus_line, quality_line;
        
        if (i < end) while (i < end && data[i] != '\n') id_line += data[i++];
        i++;

        if (i < end) while (i < end && data[i] != '\n') seq_line += data[i++];
        i++;

        if (i < end) while (i < end && data[i] != '\n') plus_line += data[i++];
        i++;

        if (i < end) while (i < end && data[i] != '\n') quality_line += data[i++];
        i++;

        // Compute average quality score
        long long total_quality = 0;
        for (char q : quality_line) {
            total_quality += (q - 33);
        }
        double avg_quality = (quality_line.empty()) ? 0 : (double)total_quality / quality_line.size();
        total_quality_sum += total_quality;
        total_chars += quality_line.size();
        // Count reads below threshold for statistics
        if (avg_quality <= QUALITY_THRESHOLD) {
            low_quality_reads++;
        }
        num_reads++;
    }

}

struct DenoiseResult {
    double avg_quality;
    int64_t total_chars;
    int64_t low_quality_reads;
    int64_t num_reads;
    int threshold;
    double low_quality_percentage;
};

/**
 * clear_pointers: None --> void
-- Clears global atomic variables for next function usage
 * @param [out] None - Resets global variables to zero
** Resets global counters for next denoise operation
*/
void clear_pointers() {
    //Clear for next function usage
    total_quality_sum = 0;
    total_chars = 0;
    low_quality_reads = 0;
    num_reads = 0;
}

/**
 * denoise: const char*, int --> DenoiseResult
-- Analyzes quality statistics of a FASTQ file without saving output
 * @param [in] file_path (const char*) - Path to the input FASTQ file
 * @param [in] threshold (int) - Quality threshold for analysis
 * @param [out] result (DenoiseResult) - Quality statistics about the file
** Main function that analyzes FASTQ quality without file output
*/
DenoiseResult denoise(const char* file_path, int threshold) {
    clear_pointers();
    std::cout << "Analyzing quality for: " << file_path << std::endl;

    DenoiseResult result;

    QUALITY_THRESHOLD = threshold;

    int fd = open(file_path, O_RDONLY);
    if (fd < 0) {
        std::cerr << "Error opening file!\n";
        return result;
    }

    // Get file size
    stat_t sb;
    if (fstat(fd, &sb) == -1) {
        std::cerr << "Error getting file size!\n";
        fd_close(fd);
        return result;
    }
    size_t file_size = sb.st_size;
    char* data = (char*)mmap(nullptr, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (data == MAP_FAILED) {
        std::cerr << "Error memory-mapping file!\n";
        fd_close(fd);
        return result;
    }
    fd_close(fd);

    // No output file needed - just analyze quality

    // Determine chunk size for threads
    size_t chunk_size = file_size / NUM_THREADS;
    std::vector<std::thread> threads;

    for (int i = 0; i < NUM_THREADS; ++i) {
        size_t start = i * chunk_size;
        size_t end = (i == NUM_THREADS - 1) ? file_size : (i + 1) * chunk_size;

        while (start > 0 && data[start - 1] != '\n') start++;
        while (end < file_size && data[end] != '\n') end++;

        //run process_chunk for each chunk to analyze quality
        
        threads.emplace_back(process_chunk, data, start, end);
    }

    // Join threads
    for (auto& t : threads) {
        t.join();
    }
    munmap(data, file_size);

    double avg_quality_per_char = total_chars ? (double)total_quality_sum / total_chars : 0;
    double low_quality_percentage = num_reads ? ((double)low_quality_reads * 100 / num_reads) : 0;
    
    std::cout << "Average quality of file: " << avg_quality_per_char << "\n";
    std::cout << "Number of reads below threshold: " << low_quality_reads << "\n";
    std::cout << "Percentage of low quality reads: " << low_quality_percentage << "%\n";
    std::cout << "Quality analysis complete - no output files saved" << std::endl;
    
    result.low_quality_reads = low_quality_reads;
    result.total_chars = total_chars;
    result.avg_quality = avg_quality_per_char;
    result.num_reads = num_reads;
    result.threshold = QUALITY_THRESHOLD;
    result.low_quality_percentage = low_quality_percentage;
    clear_pointers();
    return result;
}

PYBIND11_MODULE(denoise, m) {
    m.doc() = "FASTQ denoising module using C++";
    py::class_<DenoiseResult>(m, "DenoiseResult")
        .def(py::init<>())
        .def_readwrite("avg_quality", &DenoiseResult::avg_quality)
        .def_readwrite("total_chars", &DenoiseResult::total_chars)
        .def_readwrite("num_reads", &DenoiseResult::num_reads)
        .def_readwrite("threshold", &DenoiseResult::threshold)
        .def_readwrite("low_quality_reads", &DenoiseResult::low_quality_reads)
        .def_readwrite("low_quality_percentage", &DenoiseResult::low_quality_percentage);

    m.def("denoise", &denoise, "Analyze quality statistics of a FASTQ file",
          py::arg("file_path"), py::arg("threshold"));
}