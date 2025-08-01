## File that searches fastq files for AAV9 file sequences containing 21-mer inserts
# Written by Atul Phadke 2025 --> atulphadke8@gmail.com/phadke.at@northeastern.edu
# Inspired by Killian Hanlon's 'Shuttlecock' package --> killian@transduction.cc

from collections import Counter 
from collections import OrderedDict
from scipy.spatial.distance import hamming
import os
from Bio.Seq import Seq
import pandas as pd
from pandas import DataFrame
import pickle as pkl
import ahocorasick
import os
import inquirer
import numpy as np
from capgenie import mani
from capgenie import filter_module ## See filter_count.cpp for more info
from capgenie import fuzzy_match ## See fuzzy_match.cpp for more info
import json
import shutil

class color:
	PURPLE = '\033[95m'
	CYAN1 = '\033[96m'
	DARKCYAN = '\033[36m'
	BLUE1 = '\033[94m'
	GREEN1 = '\033[92m'
	YELLOW1 = '\033[93m'
	RED1 = '\033[91m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'
	END = '\033[0m'

class search_aav9:
    def __init__(self):
        self._save_dir = ""
        self._pkl_file_path = ""
        self._instructions_file = ""
        self._cache_folder = ""

    # save_dir is where the session is placed in cache
    @property
    def save_dir(self):
        return self._save_dir
    
    # pkl_file_path is the path where the pkl_files are stored
    @property
    def pkl_file_path(self):
        return self._pkl_file_path
    
    # points to instructions_file_path
    @property
    def intructions_file_path(self):
        return self._instructions_file
    
    # Loads instruction data
    @property
    def get_instructions_data(self):
        return pkl.load(open(self._instructions_file, "rb"))
    
    """
    confirm_peptide: CLASS, String, String --> Boolean or String
    -- Takes a Peptide and it's sequence and makes sure
    -- the sequence is in the current orientation. Returns False
    -- if no orientation is valid, otherwise returns the valid orientation
    """    
    @classmethod
    def confirm_peptide(cls, seq, peptide):
        seq = Seq(seq) 
        for nuc in [(seq), (seq.reverse_complement())]:
            for frame in range(3):
                if peptide in nuc[frame:].translate(1):
                    return str(nuc)
        return False
    
    """
    find_upstream_downstream: CLASS, [List-of String] --> String, String
    -- Takes a list of sequences with the upstream and downstream sequences
    -- and returns the common upstream and downstream sequence
    """
    @classmethod
    def find_upstream_downstream(cls, sequences):
        if not sequences:
            return None, None

        shortest_seq = min(sequences, key=len)
        upstream = ""
        downstream = ""

        # Try different lengths of upstream and downstream sequences
        for i in range(1, len(shortest_seq) // 2 + 1):  # Half-length for upstream and downstream
            # Test if the first `i` characters of the shortest sequence are present in all sequences (upstream)
            potential_upstream = shortest_seq[:i]
            if all(seq.startswith(potential_upstream) for seq in sequences):
                upstream = potential_upstream

            # Test if the last `i` characters of the shortest sequence are present in all sequences (downstream)
            potential_downstream = shortest_seq[-i:]
            if all(seq.endswith(potential_downstream) for seq in sequences):
                downstream = potential_downstream

        return upstream, downstream
    
    """
    find_amplicons: CLASS, [[String, String]], String, String --> [[String, String]]
    -- Takes the current peptide map and returns a new one without the amplicons.
    -- Also confirms each peptide sequence and returns the current orientation
    """
    @classmethod
    def find_amplicons(cls, trimmed_csv, upstream, downstream):
        peptide_map = {}
        for peptide, seq in trimmed_csv:
            # Find the positions of upstream and downstream
            start_index = seq.find(upstream) + len(upstream)
            end_index = seq.find(downstream)
            
            if start_index != -1 and end_index != -1 and start_index < end_index:
                # Extract the 21-mer amplicon in between the upstream and downstream
                nuc = cls.confirm_peptide(seq[start_index:end_index], peptide)
                if nuc:
                    peptide_map[nuc] = peptide  # This should be the 21-mer sequence
                else:
                    print("Invalid Protein: " + str(peptide))
            else:
                print("Invalid Protein: " + str(peptide))
        return peptide_map
    
    """
    trim_amplicon_sequence: CLASS, String
    -- Takes a capsid file and clears upstream and downstream sequences,
    -- then returns the new peptide map
    """
    @classmethod
    def trim_amplicon_sequence(cls, capsid_file):
        trimmed_csv = np.loadtxt(capsid_file, delimiter=",", dtype=str)
        upstream, downstream = cls.find_upstream_downstream([row[1] for row in trimmed_csv])
        peptide_map = cls.find_amplicons(trimmed_csv, upstream, downstream)
        return peptide_map
    
    """
    create_peptide_map: CLASS, String
    -- Takes a capsid file and returns a peptide map
    """
    @classmethod
    def create_peptide_map(cls, capsid_file):
        csv = np.loadtxt(capsid_file, delimiter=",", dtype=str)
        peptide_map = {}
        for lines in csv:
            nuc = cls.confirm_peptide(lines[1], lines[0])
            if nuc:
                peptide_map[nuc] = lines[0]
            else:
                print("Invalid Protein: " + lines[0])
                peptide_map[lines[1]] = lines[0]
        return peptide_map
    
    """
    load_dna_seq: string
    -- Takes a fastQ file and gets the DNA sequence from the file
    """
    def load_dna_seq(self, fastq_file):
        f=open(os.path.join(fastq_file), "r")
        content = f.read().split("\n")
        f.close()

        dna_seq = "".join(content[1::4])
        return dna_seq
    
    """
    count_known_reads: Dict(peptide, sequence), String, String, Number
    -- Takes a peptide_map from the given csv file and counts the
    -- number of occurances of every peptide. Then it prunes reads
    -- beyond a given threshold.
    """
    def count_known_reads(self, peptide_map, fastq_file, data_directory):
        new_path = os.path.join(self._pkl_file_path, data_directory)
        if not os.path.exists(new_path):
            os.mkdir(new_path)

        dna_seq = self.load_dna_seq(fastq_file=fastq_file)

        automaton = ahocorasick.Automaton()

        for pattern in peptide_map.keys():
            automaton.add_word(pattern, pattern)
        automaton.make_automaton()
        
        counts = {pattern: 0 for pattern in peptide_map.keys()}

        for end_pos, pattern in automaton.iter(dna_seq):
            counts[pattern] += 1

        # Ensure all peptides are present, fill missing with 0
        for pattern in peptide_map.keys():
            if pattern not in counts:
                counts[pattern] = 0

        sorted_count = dict(sorted(counts.items(), key=lambda item: item[1], reverse=True))
        sorted_count = {peptide_map[k]:v for k,v in sorted_count.items()}

        self.add_decimal(sorted_count, os.path.join(new_path, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))

        with open(self._instructions_file, "rb+") as file:
            content = pkl.load(file)
            if "count_known_reads" in content:
                content["count_known_reads"].append(os.path.join("pkl_files", data_directory, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))
            else:
                content["count_known_reads"] = [os.path.join("pkl_files", data_directory, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl")]
            file.seek(0)
            file.truncate()
            pkl.dump(content, file)

    def search_by_flank(self, upstream, downstream, fastq_file, data_directory):
        new_path = os.path.join(self._pkl_file_path, data_directory)
        if not os.path.exists(new_path):
            os.mkdir(new_path)

        dna_seq = self.load_dna_seq(fastq_file=fastq_file)

        A = ahocorasick.Automaton()
        A.add_word(upstream, 1)
        A.add_word(downstream, 2)
        A.make_automaton()

        f1_pos = []
        f2_pos = []

        len_f1 = len(upstream)
        len_f2 = len(downstream)

        for end, tag in A.iter(dna_seq):
            start = end - (len_f1 if tag == 1 else len_f2) + 1
            if tag == 1:
                f1_pos.append((start, end))
            else:
                f2_pos.append((start, end))

        read_counts = Counter()
        f2_idx = 0
        f2_len = len(f2_pos)

        for f1_start, f1_end in f1_pos:
            while f2_idx < f2_len and f2_pos[f2_idx][0] <= f1_end:
                f2_idx += 1
            if f2_idx >= f2_len:
                break

            f2_start, f2_end = f2_pos[f2_idx]
            read_start = f1_end + 1
            read_end = f2_start
            read_len = read_end - read_start

            if 12 <= read_len <= 25:
                read = dna_seq[read_start:read_end]
                read_counts[read] += 1

        sorted_read = dict(sorted(read_counts.items(), key=lambda item: item[1], reverse=True))
        sorted_read = self.prune_reads(0.05, sorted_read)

        self.add_decimal(sorted_read, os.path.join(new_path, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"), merc=True)

        with open(self._instructions_file, "rb+") as file:
            content = pkl.load(file)
            if "unknown_reads" in content:
                content["unknown_reads"].append(os.path.join("pkl_files", data_directory, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))
            else:
                content["unknown_reads"] = [os.path.join("pkl_files", data_directory, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl")]
            file.seek(0)
            file.truncate()
            pkl.dump(content, file)

    """
    _cpp_fuzzy_match: Dict(peptide, sequence), string, string, bool (optional)
    -- Fuzzy matches peptides in two ways: substitutions w/o indels.
    ** Note: substitutions w indels is much slower than just substitutions, but provides
    ** more accurate results
    ** Powered by edlib. Please visit and give credit at github.com/Martinos/edlib
    -- Check fuzzy_match.cpp for more info
    """
    def _cpp_fuzzy_match(self, peptide_map, fastq_file, data_directory, mismatches, subOnly=False):
        new_path = os.path.join(self._pkl_file_path, data_directory)
        if not os.path.exists(new_path):
            os.mkdir(new_path)

        dna_seq = self.load_dna_seq(fastq_file=fastq_file)

        counts = fuzzy_match.fuzzy_match(list(peptide_map.keys()), dna_seq.encode(), mismatches, subOnly)

        sorted_count = dict(sorted(counts.items(), key=lambda item: item[1], reverse=True))

        sorted_count = {peptide_map[k]:v for k,v in sorted_count.items()}

        self.add_decimal(sorted_count, os.path.join(new_path, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))

        with open(self._instructions_file, "rb+") as file:
            content = pkl.load(file)
            if "count_known_reads" in content:
                content["count_known_reads"].append(os.path.join("pkl_files", data_directory, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))
            else:
                content["count_known_reads"] = [os.path.join("pkl_files", data_directory, f"variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl")]
            file.seek(0)
            file.truncate()
            pkl.dump(content, file)

    """
    _cpp_filter_count: String, String, refseq (optional)
    -- Python wrapper for filter_count.cpp (see for more detail)
    -- Searches fastq files for AAV9 sequence containing 21-mer inserts 
    -- and pulls out, sorts and counts them. 
    """
    def _cpp_filter_count(self, data_directory, fastq_file, upstream_ref, downstream_ref):
        new_path = os.path.join(self._pkl_file_path, data_directory)
        if not os.path.exists(new_path):
            os.mkdir(new_path)

        result = filter_module.FilterResult()
        result = filter_module.filter_count(fastq_file.encode(), upstream_ref.encode(), downstream_ref.encode())

        print(len(result.forward_reads))
        print(len(result.reverse_reads))
        print(len(result.junk_reads))

        merc = self.sort_list(result.forward_reads)
         
        merc = self.prune_reads(0.05, merc)

        self.add_decimal(merc, os.path.join(new_path, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"), merc=True)

        with open(self._instructions_file, "rb+") as file:
            content = pkl.load(file)
            if "unknown_reads" in content:
                content["unknown_reads"].append(os.path.join("pkl_files", data_directory, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl"))
            else:
                content["unknown_reads"] = [os.path.join("pkl_files", data_directory, f"unknown_variants_{os.path.basename(fastq_file.replace('.fastq', ''))}.pkl")]
            file.seek(0)
            file.truncate()
            pkl.dump(content, file)

    """
    add_decimal: {String: Number}, String
    -- Add's a Decimal column to a dictionary with Peptide's and there
    -- counts
    """
    def add_decimal(self, data_dict, file, merc=False):
        df = pd.DataFrame(list(data_dict.items()), columns=["Peptide", "Count"])
        total = df["Count"].sum()
        if total == 0:
            df["Decimal"] = 0.0
        else:
            df["Decimal"] = df["Count"] / total
        # Do not filter out zeros, keep all peptides
        if merc:
            df["Peptide"] = df["Peptide"].apply(self.translate)
        df.to_pickle(file)

    """
    create_avg_pkl: String, [List-of String], String
    -- Creates an average pkl file with all the data from the other fastq 
    -- files. Adds a Decimal Column too.
    """
    def create_avg_pkl(self, data_directory, files, instruction_link):
        if instruction_link == "count_known_reads":
            file_ext = "variants_"
        else:
            file_ext = "unknown_variants_"

        df_list = [pd.read_pickle(os.path.join(self.pkl_file_path, data_directory, f"{file_ext}{file}").replace(".fastq", ".pkl")) for file in files]
        foo = []

        for d in df_list:
            obj_dict = dict(zip(d.Peptide, d.Decimal))
            foo.append(obj_dict)
        
        bar = {
            k: [d.get(k) for d in foo]
            for k in set().union(*foo)
        }

        merged_df = DataFrame.from_dict(bar, orient="index", columns=files)
        merged_df.index.name = "Peptide"
        merged_df["Average Decimal"] = merged_df[files].mean(axis=1)
        merged_df = merged_df.sort_values("Average Decimal", ascending=False)
        pkl.dump(merged_df, open(os.path.join(self._pkl_file_path, data_directory, f"average_{data_directory}.pkl"), "wb+"))
        return f"average_{data_directory}.fastq"
    
    """
    sort_list: [List-of Any] --> [List-of Any]
    -- Takes a list of peptides and sorts it based on frequency
    """
    def sort_list(self, lst):
        unsorted = Counter(lst)
        sorted_lst = sorted(unsorted.items(), key = lambda item: (-item[1], item[0]))
        return OrderedDict(sorted_lst)

    """
    prune_reads: None --> [List-of Any]
    -- Prunes similar reads beyong a given threshold
    ** Forked from Killian Hanlon's Shuttlecock package
    ** Improved for efficiency and optimization
    """
    # TODO: Create C++ wrapper for this function
    def prune_reads(self, threshold, sorted_merlist):
        highfreq_raws = []
        highfreq_translated = set()

        num_of_mers = len(sorted_merlist)

        for var, count in sorted_merlist.items():
            if count /num_of_mers >= threshold:
                translated_var = self.translate(var)
                if translated_var not in highfreq_translated:
                    highfreq_raws.append(var)
                    highfreq_translated.add(translated_var)
            else:
                break
        delset = set()
        highfreq_set = set(highfreq_raws)

        for idx, x in enumerate(highfreq_raws):
            for y in sorted_merlist:
                if y == x or y in highfreq_set:
                    continue
                #Hamming distance
                if fuzzy_match.peptide_levenshtein_distance(x, y) <= 1:
                    sorted_merlist[x] += sorted_merlist[y]
                    delset.add(y)
        for item in delset:
            del sorted_merlist[item]

        return sorted_merlist
    
    def translate(self, dna_seq):
        # Standard genetic code table
        codon_table = {
            "ATA":"I", "ATC":"I", "ATT":"I", "ATG":"M",
            "ACA":"T", "ACC":"T", "ACG":"T", "ACT":"T",
            "AAC":"N", "AAT":"N", "AAA":"K", "AAG":"K",
            "AGC":"S", "AGT":"S", "AGA":"R", "AGG":"R",
            "CTA":"L", "CTC":"L", "CTG":"L", "CTT":"L",
            "CCA":"P", "CCC":"P", "CCG":"P", "CCT":"P",
            "CAC":"H", "CAT":"H", "CAA":"Q", "CAG":"Q",
            "CGA":"R", "CGC":"R", "CGG":"R", "CGT":"R",
            "GTA":"V", "GTC":"V", "GTG":"V", "GTT":"V",
            "GCA":"A", "GCC":"A", "GCG":"A", "GCT":"A",
            "GAC":"D", "GAT":"D", "GAA":"E", "GAG":"E",
            "GGA":"G", "GGC":"G", "GGG":"G", "GGT":"G",
            "TCA":"S", "TCC":"S", "TCG":"S", "TCT":"S",
            "TTC":"F", "TTT":"F", "TTA":"L", "TTG":"L",
            "TAC":"Y", "TAT":"Y", "TAA":"*", "TAG":"*",
            "TGC":"C", "TGT":"C", "TGA":"*", "TGG":"W",
        }

        protein = []
        
        for i in range(0, len(dna_seq) - 2, 3):
            codon = dna_seq[i:i+3].upper()
            amino_acid = codon_table.get(codon, "X") 
            protein.append(amino_acid)

        return ''.join(protein)
    
    def save_denoise_result(self, result, file):
        with open(self._instructions_file, "rb") as instruction_file:
            content = pkl.load(instruction_file)
        
        with open(self._instructions_file, "wb") as instruction_file:
            if "denoise" not in content:
                content["denoise"] = [{file : {
                    "avg_quality": result.avg_quality,
                    "total_chars": result.total_chars,
                    "low_quality_reads": result.low_quality_reads,
                    "num_reads": result.num_reads,
                    "threshold": result.threshold,
                    "output_filename": result.output_filename
                }}]
            else:
                content["denoise"].append({file : {
                    "avg_quality": result.avg_quality,
                    "total_chars": result.total_chars,
                    "low_quality_reads": result.low_quality_reads,
                    "num_reads": result.num_reads,
                    "threshold": result.threshold,
                    "output_filename": result.output_filename
                }})
            print(content)
            pkl.dump(content, instruction_file)
            

    def _serialize_pkl(self):
        with open(self._instructions_file, "rb+") as instruction_file:
            content = pkl.load(instruction_file)
        
        with open(os.path.join(self._cache_folder, self._save_dir, "instruction.json"), "w") as f:
            json.dump(content, f)

    """
    init_session: None
    -- Creates a new session based on user input and handles
    -- file paths for the future
    """
    def init_session(self):
        self._cache_folder = os.path.expanduser(mani.get_cache_folder())
        if not os.path.exists(self._cache_folder):
            os.mkdir(self._cache_folder)

        sessions = os.listdir(self._cache_folder)

        if len(sessions) > 0:
            sessions.append("Create new one")
            questions = [
                inquirer.List("Previous sessions",
                              message="You have some previous sessions below",
                              choices=sessions,
                              ),
            ]
            answers = inquirer.prompt(questions)["Previous sessions"]
            if answers == "Create new one":
                self._save_dir = input("Type a name for this session: ")
                os.mkdir(os.path.join(self._cache_folder, self._save_dir))
                self._instructions_file = os.path.join(self._cache_folder, self._save_dir, "instructions.pkl")
                with open(self._instructions_file, "wb") as f:
                    pkl.dump({"Session": self._save_dir}, f)
            else:
                self._save_dir = answers
                self._instructions_file = os.path.join(self._cache_folder, self._save_dir, "instructions.pkl")
        else:
            print("You have no previous sessions, creating a new one...")
            self._save_dir = input("Type a name for this session: ")
            self._instructions_file = os.path.join(self._cache_folder, self._save_dir, "instructions.pkl")
            os.mkdir(os.path.join(self._cache_folder, self._save_dir))
            with open(self._instructions_file, "wb") as f:
                pkl.dump({"Session": self._save_dir}, f)

        self._pkl_file_path = os.path.join(self._cache_folder, self._save_dir, "pkl_files")
        if not os.path.exists(self._pkl_file_path):
            os.mkdir(self._pkl_file_path)
        
    """
    _override_session: str --> void
    -- Creates a new session based on session_name,
    -- THIS IS USED FOR THE DESKTOP APPLICATION
    """
    def _override_session(self, session_folder):
        self._cache_folder = os.path.expanduser(mani.get_cache_folder())

        if not os.path.exists(self._cache_folder):
            os.mkdir(self._cache_folder)
            
        self._save_dir = session_folder
        self._instructions_file = os.path.join(self._cache_folder, self._save_dir, "instructions.pkl")
        
        os.mkdir(os.path.join(self._cache_folder, self._save_dir))
        with open(self._instructions_file, "wb") as f:
            pkl.dump({"Session": self._save_dir}, f)

        self._pkl_file_path = os.path.join(self._cache_folder, self._save_dir, "pkl_files")
        if not os.path.exists(self._pkl_file_path):
            os.mkdir(self._pkl_file_path)

    def save_to_output(self, output_dir):
        dir_to_copy = os.path.join(self._cache_folder, self._save_dir)
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        try:
            shutil.copytree(dir_to_copy, output_dir, dirs_exist_ok=True)
            print(f"Successfully copied contents of '{dir_to_copy}' to '{output_dir}'")
        except shutil.Error as e:
            print(f"Error copying directory: {e}")
        except OSError as e:
            print(f"Error creating destination directory: {e}")