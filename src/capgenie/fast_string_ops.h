#ifndef FAST_STRING_OPS_H
#define FAST_STRING_OPS_H

#include <string>
#include <vector>
#include <algorithm>
#include <unordered_map>

// Boyer-Moore-Horspool string search algorithm
int fast_string_search(const std::string& text, const std::string& pattern) {
    int n = text.length();
    int m = pattern.length();
    
    if (m == 0 || m > n) return -1;
    
    // Bad character table
    std::unordered_map<char, int> bad_char_table;
    for (int i = 0; i < m - 1; ++i) {
        bad_char_table[pattern[i]] = m - 1 - i;
    }
    
    int i = m - 1;
    while (i < n) {
        int j = m - 1;
        int k = i;
        
        while (j >= 0 && text[k] == pattern[j]) {
            j--;
            k--;
        }
        
        if (j == -1) {
            return k + 1;  // Pattern found
        }
        
        // Use bad character rule
        char c = text[i];
        auto it = bad_char_table.find(c);
        if (it != bad_char_table.end()) {
            i += it->second;
        } else {
            i += m;
        }
    }
    
    return -1;  // Pattern not found
}

// Find all occurrences of pattern in text
std::vector<int> fast_find_all(const std::string& text, const std::string& pattern) {
    std::vector<int> positions;
    int n = text.length();
    int m = pattern.length();
    
    if (m == 0 || m > n) return positions;
    
    // Bad character table
    std::unordered_map<char, int> bad_char_table;
    for (int i = 0; i < m - 1; ++i) {
        bad_char_table[pattern[i]] = m - 1 - i;
    }
    
    int i = m - 1;
    while (i < n) {
        int j = m - 1;
        int k = i;
        
        while (j >= 0 && text[k] == pattern[j]) {
            j--;
            k--;
        }
        
        if (j == -1) {
            positions.push_back(k + 1);
            i += 1;  // Move one position to find overlapping matches
        } else {
            // Use bad character rule
            char c = text[i];
            auto it = bad_char_table.find(c);
            if (it != bad_char_table.end()) {
                i += it->second;
            } else {
                i += m;
            }
        }
    }
    
    return positions;
}

// DNA-specific optimizations
class DNAProcessor {
private:
    static const int ALPHABET_SIZE = 4;
    static const char DNA_CHARS[4];
    
public:
    // Convert DNA character to index (0-3)
    static int char_to_index(char c) {
        switch (c) {
            case 'A': return 0;
            case 'C': return 1;
            case 'G': return 2;
            case 'T': return 3;
            default: return -1;
        }
    }
    
    // Find DNA pattern with optimized search
    static std::vector<int> find_dna_pattern(const std::string& sequence, const std::string& pattern) {
        return fast_find_all(sequence, pattern);
    }
    
    // Count k-mers efficiently
    static std::unordered_map<std::string, int> count_kmers(const std::string& sequence, int k) {
        std::unordered_map<std::string, int> kmer_counts;
        int n = sequence.length();
        
        if (k > n) return kmer_counts;
        
        for (int i = 0; i <= n - k; ++i) {
            std::string kmer = sequence.substr(i, k);
            kmer_counts[kmer]++;
        }
        
        return kmer_counts;
    }
};

// Define the static array
const char DNAProcessor::DNA_CHARS[4] = {'A', 'C', 'G', 'T'};

#endif // FAST_STRING_OPS_H 