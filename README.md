# rnaseqSim
For SMC-RNA challenge, code for analyzing datasets of validated fusions and generating synthetic fusion data.

## CWL Workflow:

Running the workflow requires CWL v1.0+ and Docker.

## Generate a diploid genome with phased variants from HG002 NIST data
This first step takes a haploid genome reference and produces a diploid reference with alterations based on an input VCF. The VCF will ideally contain phased genotypes. It also modifies a transcriptome GTF to produce a matching diploid GTF. Lastly, it produces a RSEM and STAR index based on the diploid data sufficient for running quantification.

First, download some pre-requisite files:
`bash wget_genome_files.sh`

The CWL JSON config file mimimally requires these inputs:
 * INPUT_HAPLOID_FILE - Reference genome FASTA.[downloaded]
 * INPUT_VCF_FILE - VCF containing alleles(Ref,Alt).[downloaded]
 * INPUT_GTF_FILE - Transcript GTF corresponding to same genome FASTA build.[downloaded]
 * REF_NAME - Prefix name that will be used to name outputs.
 * NUM_CORES - Number of cores for STAR index generation.

Run the CWL workflow:

`cwltool workflow/create_diploid_genome.cwl create_diploid_genome.json`

*Note*- The index step is the longest and can take several hours depending on the number of cores allocated.

Outputs:
 * {REF_NAME}_diploid_final.GTF - GTF transcripts for diploid data
 * {REF_NAME}_diploid_final.fa - Genome FASTA for diploid data
 * {REF_NAME}_diploid_final_rsem-index.tar.gz - RSEM & STAR indexes for diploid data

*Note*-Advanced users can modify the JSON inputs to suit different genetic backgrounds
*Note*-You may want to save these files in synapse for later use.
*Note*-Indels do NOT work yet due to the offset they introduce. You can only use a VCF with SNPs.

--------------------------------------------------------------------------------------------------

## Generate Fusions(pre-requisite)

Two files must be generated or obtained before advancing to the next step. You can use the index from the previous step(unpack it) and some existing sample FASTQ data to produce the necessary files.

Run the quantification on some sample data:

`docker run -it -v /mounts:/mounts -w /mounts/isilon/data/eahome/q804348/myprogs/rnaseqSim/  andrewlambsage/rnaseqsim rsem-calculate-expression --star --seed 19 -p 12 --star-gzipped-read-file --paired-end input_data/MCF7_2_L1.D708_501_1.fastq.gz input_data/MCF7_2_L1.D708_501_2.fastq.gz RSEM_INDEX/GRCH37_diploid  MCF7_2_L1.D708_501`

These two files are necessary for downstream steps:
1. RSEM_MODEL - {SAMPLE}.rsem.stat/{SAMPLE}.rsem.model
2. EXPRESSION_PROFILE - {SAMPLE}.isoforms.results

---------------------------------------------------------------------------------------------------

## Generate Fusion

Run the CWL workflow:

`cwltool workflow/fusion_simulation_workflow.cwl [INPUT.JSON]`
`cwltool workflow/fusion_simulation_workflow_all.cwl [INPUT.JSON]`

The input JSON minimally needs these fields:
  * SIM_NAME: Prefix name to be used to name outputs
  * GTF: A GTF file of transcripts
  * NUM_EVENTS: The number of filtered fusion events to simulate.
  * TARGET_DEPTH: The average target depth of transcript coverage.
  * GENOME: A gzipped FASTA for the haploid reference genome.
  * EXPRESSION_PROFILE: RSEM output, {SAMPLE}.isoforms.results
  * RSEM_MODEL: RSEM output, {SAMPLE}.rsem.stat/{SAMPLE}.rsem.model
  * DIP_GENOME: File

And can use the optional fields:
  SEED: ["null", int]
  MID_EXON_FUSIONS: ["null", boolean]

## Description of inputs

SIM_NAME:
GTF:
NUM_EVENTS:
TARGET_DEPTH:
GENOME:
EXPRESSION_PROFILE:
RSEM_MODEL:
DIP_GENOME:

SEED: (optional) If given all scripts with a random element in the
workflow will have a seed set at the given integer.

MID_EXON_FUSIONS: (optional) If set to true, fusions will happen in the middle
of exons

## Description of outputs

[SIM_NAME]_filtered.bedpe:

[SIM_NAME]_isoforms_truth.txt:

[SIM_NAME]_mergeSort_1.fq.gz:

[SIM_NAME]_mergeSort_2.fq.gz:

archive.tgz: This will store other intermediate files if
`fusion_simulation_workflow_all.cwl`was used.

----------------------------------------------------------------------------------------
# older descriptions:

## Requirements:

[STAR 2.4.2a] (https://github.com/alexdobin/STAR/archive/STAR_2.4.2a.tar.gz)

[RSEM v1.2.31] (https://github.com/deweylab/RSEM/archive/v1.2.31.tar.gz)

## Required Inputs

Diploid Genome - Homo_sapiens.GRCh37.75.primary.diploid.fa.gz (syn8348583)

Diploid GTF - Hsapiens_Ensembl_v75_diploid.gtf.gz (syn8348617)

Reference GTF - Hsapiens_Ensembl_v75_refonly.gtf (syn8348668)

Model file - CPCG_0258.R1.fastq.model (syn8348382)

Expression profile -


## Basic Steps:

Step 1 - Index Diploid Genome:

`rsem-prepare-reference --gtf [diploid.ref.gtf] --star [diploid.ref.fa] [Index name]`

Step 2 - Create fusion events, truth file, and RSEM-format fusion reference:

`fusion_create/module.py --gtf Hsapiens_Ensembl_v75_refonly.gtf --numEvents [XX] --simName [simName]`

Step 3 - Adjust estimated isoform values to include expression for fusion genes according to a model:

`model_isoforms/modify_model_tpm_for_diploid.R --TPM [input expression profile] --gtf [simName.gtf] --targetDepth [XX] --codeDir [/path/to/code] &> [output.log]`

Step 4 - Generate reads from diploid and fusion references:

`fastq_create/generate_reads.py --totalReads [targetDepth * 1000000] --numSimReads [output.log] --simName [simName] --RSEMmodel [model file] --isoformTPM [model_isoforms output] --fusionTPM [model_isoforms output] --fusRef [fusion_create output]`

