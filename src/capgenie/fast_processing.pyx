# cython: language_level=3
# distutils: language=c++
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True

import cython
from cpython cimport array
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map
from libcpp.pair cimport pair
from libcpp cimport bool
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

import numpy as np
cimport numpy as np

# Type definitions for better performance
ctypedef unsigned long long uint64_t
ctypedef unsigned int uint32_t

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_load_dna_seq(str fastq_file):
    """
    Optimized FASTQ sequence loading using Cython
    Only reads sequence lines (every 4th line starting from line 1)
    """
    cdef:
        list sequences = []
        str line
        int line_num = 0
    
    with open(fastq_file, "r") as f:
        for line in f:
            line_num += 1
            if line_num % 4 == 1:  # Sequence lines (1, 5, 9, ...)
                sequences.append(line.strip())
    
    return "".join(sequences)

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_count_patterns(str dna_seq, list patterns):
    """
    Optimized pattern counting using Boyer-Moore-Horspool algorithm
    """
    cdef:
        dict counts = {}
        str pattern
        int count
        int i, j, k
        int n = len(dna_seq)
        int m
        dict bad_char_table
        char c
    
    # Initialize counts
    for pattern in patterns:
        counts[pattern] = 0
    
    for pattern in patterns:
        m = len(pattern)
        if m == 0 or m > n:
            continue
            
        # Build bad character table
        bad_char_table = {}
        for i in range(m - 1):
            bad_char_table[pattern[i]] = m - 1 - i
        
        # Boyer-Moore-Horspool search
        i = m - 1
        while i < n:
            j = m - 1
            k = i
            while j >= 0 and dna_seq[k] == pattern[j]:
                j -= 1
                k -= 1
            
            if j == -1:  # Pattern found
                counts[pattern] += 1
                i += 1
            else:
                # Use bad character rule
                c = dna_seq[i]
                if c in bad_char_table:
                    i += bad_char_table[c]
                else:
                    i += m
    
    return counts

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_find_flanks(str dna_seq, str upstream, str downstream):
    """
    Optimized flanking sequence search
    Returns positions of upstream and downstream sequences
    """
    cdef:
        list upstream_pos = []
        list downstream_pos = []
        int i, j, k
        int n = len(dna_seq)
        int len_up = len(upstream)
        int len_down = len(downstream)
        bool found
    
    # Find upstream positions
    for i in range(n - len_up + 1):
        found = True
        for j in range(len_up):
            if dna_seq[i + j] != upstream[j]:
                found = False
                break
        if found:
            upstream_pos.append((i, i + len_up - 1))
    
    # Find downstream positions
    for i in range(n - len_down + 1):
        found = True
        for j in range(len_down):
            if dna_seq[i + j] != downstream[j]:
                found = False
                break
        if found:
            downstream_pos.append((i, i + len_down - 1))
    
    return upstream_pos, downstream_pos

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_extract_reads(list upstream_pos, list downstream_pos, str dna_seq, int min_len=12, int max_len=25):
    """
    Optimized read extraction between flanking sequences
    """
    cdef:
        dict read_counts = {}
        int f2_idx = 0
        int f2_len = len(downstream_pos)
        int f1_start, f1_end, f2_start, f2_end
        int read_start, read_end, read_len
        str read
    
    for f1_start, f1_end in upstream_pos:
        # Find next downstream position
        while f2_idx < f2_len and downstream_pos[f2_idx][0] <= f1_end:
            f2_idx += 1
        
        if f2_idx >= f2_len:
            break
        
        f2_start, f2_end = downstream_pos[f2_idx]
        read_start = f1_end + 1
        read_end = f2_start
        read_len = read_end - read_start
        
        if min_len <= read_len <= max_len:
            read = dna_seq[read_start:read_end]
            if read in read_counts:
                read_counts[read] += 1
            else:
                read_counts[read] = 1
    
    return read_counts

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_merge_counts(list data_dicts):
    """
    Optimized merging of count dictionaries
    """
    cdef:
        dict merged = {}
        dict d
        str key
        int value
    
    for d in data_dicts:
        for key, value in d.items():
            if key in merged:
                merged[key] += value
            else:
                merged[key] = value
    
    return merged

@cython.boundscheck(False)
@cython.wraparound(False)
def fast_calculate_decimals(dict counts):
    """
    Optimized decimal calculation from counts
    """
    cdef:
        dict decimals = {}
        double total = 0.0
        str key
        double decimal_value
    
    # Debug: Print sample data types
    if len(counts) > 0:
        sample_key = list(counts.keys())[0]
        sample_value = counts[sample_key]
        print(f"CYTHON DEBUG: Sample key type: {type(sample_key)}, value type: {type(sample_value)}, value: {sample_value}")
    
    # Calculate total - handle different data types
    for key, value in counts.items():
        if hasattr(value, '__float__'):
            total += float(value)
        elif hasattr(value, 'item'):  # numpy scalar
            total += value.item()
        else:
            try:
                total += float(value)
            except (ValueError, TypeError):
                print(f"CYTHON DEBUG: Failed to convert value {value} of type {type(value)}")
                continue
    
    # Debug: Print total
    print(f"CYTHON DEBUG: Total calculated: {total}")
    
    # Calculate decimals
    if total > 0:
        for key, value in counts.items():
            if hasattr(value, '__float__'):
                decimal_value = float(value) / total
            elif hasattr(value, 'item'):  # numpy scalar
                decimal_value = value.item() / total
            else:
                try:
                    decimal_value = float(value) / total
                except (ValueError, TypeError):
                    decimal_value = 0.0
            
            decimals[key] = decimal_value
    else:
        for key in counts.keys():
            decimals[key] = 0.0
    
    # Debug: Print sample decimals
    if len(decimals) > 0:
        sample_key = list(decimals.keys())[0]
        sample_decimal = decimals[sample_key]
        print(f"CYTHON DEBUG: Sample decimal for {sample_key}: {sample_decimal}")
    
    return decimals

# C++ integration for ultra-fast string operations
cdef extern from "fast_string_ops.h":
    int fast_string_search(const string& text, const string& pattern)
    vector[int] fast_find_all(const string& text, const string& pattern)

def fast_string_search_cy(str text, str pattern):
    """
    Cython wrapper for C++ fast string search
    """
    cdef:
        string cpp_text = text.encode('utf-8')
        string cpp_pattern = pattern.encode('utf-8')
        int result
    
    result = fast_string_search(cpp_text, cpp_pattern)
    return result

def fast_find_all_cy(str text, str pattern):
    """
    Cython wrapper for C++ fast find all occurrences
    """
    cdef:
        string cpp_text = text.encode('utf-8')
        string cpp_pattern = pattern.encode('utf-8')
        vector[int] result
    
    result = fast_find_all(cpp_text, cpp_pattern)
    return [pos for pos in result] 