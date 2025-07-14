#include <string>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <unordered_map>
#include "translate.h"

namespace py = pybind11;

// getOrDefault: map, key, default
// -- Returns a value of map if found, otherwise returns default
template <typename K, typename V>
V getOrDefault(const std::unordered_map<K, V>& m, const K& key, const V& default_value) {
    auto it = m.find(key);
    return (it != m.end()) ? it->second : default_value;
}

/* translate: dna_sequence (string)
-- Takes a DNA sequence and translates into a
peptide sequence. */
std::string translate(std::string dna_sequence) {
    // Codon table generated from ChatGPT
    std::unordered_map<std::string, std::string> codon_table = {
        // Phenylalanine
        {"TTT", "F"}, {"TTC", "F"},
        // Leucine
        {"TTA", "L"}, {"TTG", "L"}, {"CTT", "L"}, {"CTC", "L"}, {"CTA", "L"}, {"CTG", "L"},
        // Isoleucine
        {"ATT", "I"}, {"ATC", "I"}, {"ATA", "I"},
        // Methionine (Start)
        {"ATG", "M"},
        // Valine
        {"GTT", "V"}, {"GTC", "V"}, {"GTA", "V"}, {"GTG", "V"},
        // Serine
        {"TCT", "S"}, {"TCC", "S"}, {"TCA", "S"}, {"TCG", "S"}, {"AGT", "S"}, {"AGC", "S"},
        // Proline
        {"CCT", "P"}, {"CCC", "P"}, {"CCA", "P"}, {"CCG", "P"},
        // Threonine
        {"ACT", "T"}, {"ACC", "T"}, {"ACA", "T"}, {"ACG", "T"},
        // Alanine
        {"GCT", "A"}, {"GCC", "A"}, {"GCA", "A"}, {"GCG", "A"},
        // Tyrosine
        {"TAT", "Y"}, {"TAC", "Y"},
        // Histidine
        {"CAT", "H"}, {"CAC", "H"},
        // Glutamine
        {"CAA", "Q"}, {"CAG", "Q"},
        // Asparagine
        {"AAT", "N"}, {"AAC", "N"},
        // Lysine
        {"AAA", "K"}, {"AAG", "K"},
        // Aspartic Acid
        {"GAT", "D"}, {"GAC", "D"},
        // Glutamic Acid
        {"GAA", "E"}, {"GAG", "E"},
        // Cysteine
        {"TGT", "C"}, {"TGC", "C"},
        // Tryptophan
        {"TGG", "W"},
        // Arginine
        {"CGT", "R"}, {"CGC", "R"}, {"CGA", "R"}, {"CGG", "R"}, {"AGA", "R"}, {"AGG", "R"},
        // Glycine
        {"GGT", "G"}, {"GGC", "G"}, {"GGA", "G"}, {"GGG", "G"},
        // Stop codons
        {"TAA", "*"}, {"TAG", "*"}, {"TGA", "*"}
    };

    std::string current_amino;
    std::string peptide;

    for (int i = 0; i < dna_sequence.length() - 2; i += 3) {
        current_amino = getOrDefault(codon_table, dna_sequence.substr(i, i+3), std::string("X"));
        if (current_amino == "*") {
            break;
        }
        peptide += current_amino;
    }

    return peptide;
}

PYBIND11_MODULE(translate, m) {
    m.doc() = "Fastest translate method using C++";
    m.def("translate", &translate, "Translation method",
        py::arg("dna_sequence"));
}


