# RNA-Seq Analysis - Learning

How I learnt RNA-Seq analysis using public FASTQ data, FASTQC, Skewer using the work of Mandhri Abeysooriya (GitHub)

Using this README as a means to show complete understanding and include additional technical troubleshooting which I encountered while attempting to follow her RNA-Seq steps

## Features

- Aid in understanding how to use bash for data download and pre-processing
- Common troubleshooting and errors that I encountered
- Download and use of common RNA-Seq tools

## Installation requirements

### FastQC installation

```bash
sudo apt-get update
sudo apt-get install fastqc
```
#### FastQC - Overview

FASTQC assesses the quality of the data provided

- Measures the accuracy of base calls using Phred quality scores
  - Can be as a mean value across base values or individual bases
  
- Provides plots and summaries for:
  - Adapter content: Scanning for leftover sequencing adapters
  - Duplication levels: How many identical sequences appear in the FASTQ file (High levels expected in RNA-Seq data)
  - Per base N content: Proportion of bases unable to be confidently read
  - Per base quality: Phread scores
  - Per base sequence content: Proportion of base occurrence (A, C, G, T)
  - Per sequence GC content: Quality assessment based on GC distribution in read
  
  
### MultiQC installation

```bash
pip install --user multiqc
```

#### MultiQC - Overview

MULTIQC aggregates your FASTQC data and creates reports for multiple samples used
- Allows the direct comparison between samples as well as commonalities between 


### Skewer installation

```bash
# Compile from source
git clone https://github.com/relipmoc/skewer.git
cd skewer
make
sudo make install
```

#### Skewer - Overview

Trims technical artifacts used during sequencing
- Trims adapter sequences that allow attachment of fragments
- Trims low quality bases based on Phred scores at the end of reads
- Removes reads that become to short after trimming


## Step 1: Data Download

### Preparing Download Links

The data download process has been automated to retrieve all FASTQ files associated with a specific ENA study accession. The download script performs the following operations:

1. **API Query**: ENA's file report API is queried to retrieve all FASTQ download URLs
2. **URL Processing**: FTP URLs are extracted and formatted appropriately
3. **Parallel Download**: Multiple files are downloaded concurrently using wget

### Configuration Parameters

The download script utilises several configurable parameters:

```bash
ENA_STUDY="SRP080947"                           # Target ENA study accession
OUTDIR="/mnt/vol1/RNA-Seq/fastq_files"         # Output directory path
LINKFILE="/mnt/vol1/RNA-Seq/ena_ftp_links.txt" # Generated URL list file
N_CORES=6                                       # Parallel download threads
```

### Executing Download

```bash
./download_sra.sh
```

The script automatically:
- Creates the output directory structure
- Queries ENA API for all FASTQ files in the specified study
- Generates `ena_ftp_links.txt` containing all download URLs
- Downloads files in parallel using the specified number of cores
- Provides progress feedback and error handling

Troubleshooting:
- Most common error is not changing the directory in the download code. The
download code itself runs a script that executes the command. Check the code to
ensure the directory in the script matches the directory you wish to execute the
script in. This is essential for every script ran!

## Step 2: Quality control

Quality metrics are generated for all raw FASTQ files:

```bash
# Generate individual FastQC reports
fastqc -o qc_raw/ fastq_files/*.fastq.gz

# Compile aggregated MultiQC report
multiqc -o qc_raw/ qc_raw/
```

Quality reports will be available in the `qc_raw/` directory for examination.

Examining the code:
- qc_raw is a new directory that is made with this code
- "*" filters files that have the specific phrase after it in this case
looking only at fastq.gz files
- Overall, takes the data files in the fastqc_files directory and creates fastqc
reports in new directory qc_raw
- Multiqc takes those reports in qc_raw and creates a multiqc report in the 
directory qc_raw

Problems that may be encountered:
- Make sure you are in the right working directory using cd when running the 
code otherwise the fastqc_files directory may not be found
- If an error is received like: "No files named qc_raw are found", you may 
have to manually create the directory using mkdir

These reports can be viewed on R

## Step 3: Adapter Removal


### Read Trimming Execution
Most trimmers detect adapters for single-end reads. 

```bash
# Single-end trimming with fastp (auto-detect adapters)
./fastq_trimmer.sh \
  --in-dir fastq_files/ \
  --out-dir fastq_trimmed/
```

Trimmed reads will be written to the `fastq_trimmed/` directory.

Examining the code:
- Creates a new directory "fastq_trimmed" where fastqc files from the 
directory fastq_files are trimmed
- Examining the script "fastq_trimmer.sh" highlights they are trimmed based on 
Phred scores and nucleotide length of read

Troubleshooting:
- Same principles apply as the last script ran
- Ensure the name of the script written in code is as saved, ./ executes said script

## Step 4: Transcript Quantification

### Reference Preparation (transcriptome)

Kallisto builds an index from a **transcriptome FASTA** (e.g., Ensembl cDNA), not from a genome FASTA.
Use a transcriptome that matches your GTF **and release version**.  
In this project we use **mouse (Mus musculus), GRCm39, Ensembl r115**.

```bash
# Create an index once (example paths)
PROJ_DIR=/mnt/vol1/Mouse_model_RNA_Seq
INDEX_DIR="$PROJ_DIR/index"
mkdir -p "$INDEX_DIR"
cd "$INDEX_DIR"

# Download Ensembl r115 mouse cDNA transcriptome
wget -O Mus_musculus.GRCm39.cdna.all.fa.gz \
  https://ftp.ensembl.org/pub/release-115/fasta/mus_musculus/cdna/Mus_musculus.GRCm39.cdna.all.fa.gz

# Build Kallisto index from cDNA (default k=31)
gunzip -c Mus_musculus.GRCm39.cdna.all.fa.gz > transcripts.fa
kallisto index -i mouse_transcriptome.r115.k31.idx transcripts.fa

```

After preparing the index, quantify your samples with the relevant index and reads.

Examining the code:
- Uses wget to pull data from link
- Uses gunzip -c to uncompress the data and redirect it into a FASTA file "transcripts.fa"
- Builds the kallisto index into file "mouse_transcriptome.r115.k31.idx"

Troubleshooting:
- A problem I encountered was that I ran this code on a standard laptop with little
available RAM, and the process was killed.

The way around this:
```bash
# 1. Allocate an 8 GB file
sudo fallocate -l 8G /swapfile

# 2. Secure file permissions
sudo chmod 600 /swapfile

# 3. Format it as swap space
sudo mkswap /swapfile

# 4. Turn the swap on
sudo swapon /swapfile

# 5. Verify swap is active
free -h

```

This code creates a temporary 8G swap file to use as additional ran. It allocates
8G of disk space as virtual memory.
- Using free -h shows your available RAM. Around 5-6 GB is required to run kallisto index

Once done you can run this code to delete the swap file:

```bash
sudo swapoff /swapfile
sudo rm /swapfile
```

### Single-End Quantification

Kallisto requires the fragment length mean (-l) and sd (-s) for single-end.

```bash
kallisto quant --single \
  -i "$INDEX_DIR/mouse_transcriptome.r115.k31.idx" \
  -o /mnt/vol1/Mouse_model_RNA_Seq/kallisto_results/SAMPLE_ID_SE \
  -t 16 \
  -l 200 -s 20 \
  /path/to/trimmed/SAMPLE_ID_trimmed.fastq.gz
```


  
  
  
