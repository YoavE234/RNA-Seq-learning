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
  
  
  