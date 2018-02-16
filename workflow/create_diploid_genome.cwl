#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: Workflow

doc: "Diploid Genome Creation Workflow"

requirements:
  - class: MultipleInputFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  INPUT_HAPLOID_FILE: File
  INPUT_VCF_FILE: File
  INPUT_GTF_FILE: File
  REF_NAME: string
  NUM_CORES: {type: int, default: 1}
  INPUT_VCF_HAP1: {type: string, default: "1"}
  INPUT_VCF_HAP2: {type: string, default: "2"}
  SUFFIX_STRING1: {type: string, default: "hap1"}
  SUFFIX_STRING2: {type: string, default: "hap2"}
  SED_STRING1: {type: string, default: "s/>\\([[:graph:]]*\\)\\s/>\\1-hap1 /g"}
  SED_STRING2: {type: string, default: "s/>\\([[:graph:]]*\\)\\s/>\\1-hap2 /g"}


outputs:
  OUTPUT:
    type:
      type: array
      items: File
    outputSource: [tar_create/archive, combine_gtfs/output_file, combine_fastas/output_file]

steps:

  index_vcf1:
    run: ../genome_create/cwl/index_vcf.cwl
    in:
      input_vcf: INPUT_VCF_FILE
    out: [output_index]

  add_variants1:
    run: ../genome_create/cwl/add_variants.cwl
    in:
      input_fasta: INPUT_HAPLOID_FILE
      output_fasta_name:
        source: SUFFIX_STRING1
        valueFrom: $(self)_genome.fa
      input_vcf: index_vcf1/output_index
      haplotype_which : INPUT_VCF_HAP1
    out: [output_fasta]

  add_variants2:
    run: ../genome_create/cwl/add_variants.cwl
    in:
      input_fasta: INPUT_HAPLOID_FILE
      output_fasta_name:
        source: SUFFIX_STRING2
        valueFrom: $(self)_genome.fa
      input_vcf: index_vcf1/output_index
      haplotype_which : INPUT_VCF_HAP2
    out: [output_fasta]

  rename_fasta_features1:
    run: ../general_tools/sed_rename.cwl
    in:
      input_string: SED_STRING1
      input_file: add_variants1/output_fasta
      out_filename:
        source: SUFFIX_STRING1
        valueFrom: $(self)_genome_renamed.fa
    out: [output_file]

  rename_fasta_features2:
    run: ../general_tools/sed_rename.cwl
    in:
      input_string: SED_STRING2
      input_file: add_variants2/output_fasta
      out_filename:
        source: SUFFIX_STRING2
        valueFrom: $(self)_genome_renamed.fa
    out: [output_file]

  combine_fastas:
    run: ../general_tools/cat_files.cwl
    in:
      input_files: [rename_fasta_features1/output_file, rename_fasta_features2/output_file]
      out_filename:
        source: REF_NAME
        valueFrom: $(self)_final.fa
    out: [output_file]

  rename_gtf_features1:
    run: ../genome_create/cwl/rename_gtf_features.cwl
    in:
      input_string: SUFFIX_STRING1
      input_gtf: INPUT_GTF_FILE
      out_filename:
        source: SUFFIX_STRING1
        valueFrom: $(self).GTF
    out: [output_gtf]

  rename_gtf_features2:
    run: ../genome_create/cwl/rename_gtf_features.cwl
    in:
      input_string: SUFFIX_STRING2
      input_gtf: INPUT_GTF_FILE
      out_filename:
        source: SUFFIX_STRING2
        valueFrom: $(self).GTF
    out: [output_gtf]

  combine_gtfs:
    run: ../general_tools/cat_files.cwl
    in:
      input_files: [rename_gtf_features1/output_gtf, rename_gtf_features2/output_gtf]
      out_filename:
        source: REF_NAME
        valueFrom: $(self)_final.GTF
    out: [output_file]

  prepare_reference:
    run: ../genome_create/cwl/prepare_reference.cwl
    in:
      input_gtf: combine_gtfs/output_file
      num_cores: NUM_CORES
      input_fasta: combine_fastas/output_file
      ref_name: REF_NAME
    out: [output_chrlist, output_grp, output_Log.out, output_n2g.idx.fa, output_idx.fa, output_seq, output_ti, output_transcripts.fa]

  tar_create:
    run: ../general_tools/tar_files.cwl
    in:
      input_files:
        - prepare_reference/output_chrlist
        - prepare_reference/output_grp
        - prepare_reference/output_Log.out
        - prepare_reference/output_n2g.idx.fa
        - prepare_reference/output_idx.fa
        - prepare_reference/output_seq
        - prepare_reference/output_ti
        - prepare_reference/output_transcripts.fa
      out_filename:
        source: REF_NAME
        valueFrom: $(self)_final.tar.gz
    out: [archive]
