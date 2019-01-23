#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: "Fusion Simulation Workflow"

requirements:
  - class: MultipleInputFeatureRequirement

inputs:
  SIM_NAME: string
  GTF: File
  GENOME: File
  EXPRESSION_PROFILE: File
  RSEM_MODEL: File
  GENOME_INDEX: Directory
  NUM_EVENTS: {type: int, default: 5}
  TARGET_DEPTH: {type: int, default: 20}
  SEED: {type: int, default: 19}
  MID_EXON_PROB: ["null", float]
  MID_EXON_MIN_SIZE: ["null", int]
  MID_EXON_MIN_CLEAVED: ["null", int]

outputs:
  OUTPUT:
    type:
      type: array
      items: File
    outputSource: [fusion/fusionTruth, reads/isoformTruth, reads/fastq1, reads/fastq2]# , archive/archive]

steps:

  # tar:
  #   run: ../general_tools/tar_extract.cwl
  #   in:
  #     input: DIP_GENOME
  #   out: [output]

  # gunzip:
  #   run: ../general_tools/gunzip.cwl
  #   in:
  #     input: GENOME
  #   out: [output]

  fusion:
    run: ../fusion_create/cwl/create_fusion.cwl
    in:
      gtf: GTF
      genome: GENOME
      numEvents: NUM_EVENTS
      simName: SIM_NAME
      seed: SEED
      mid_exon_prob: MID_EXON_PROB
      mid_exon_min_size: MID_EXON_MIN_SIZE
      mid_exon_min_cleaved: MID_EXON_MIN_CLEAVED
    out: [fusGTF, fusRef, fusionTruth, fusLog, fusFA]

  isoform:
    run: ../model_isoforms/cwl/model_isoforms.cwl
    in:
      tpm: EXPRESSION_PROFILE
      gtf: fusion/fusGTF
      depth: TARGET_DEPTH
      seed: SEED
    out: [isoformTPM, fusionTPM, isoformLog]

  reads:
    run: ../fastq_create/cwl/create_fastq.cwl
    in:
      totalReads: TARGET_DEPTH
      simName: SIM_NAME
      RSEMmodel: RSEM_MODEL
      isoformTPM: isoform/isoformTPM
      fusionTPM: isoform/fusionTPM
      fusion_bedpe: fusion/fusionTruth
      fusRef: fusion/fusRef
      dipGenome: GENOME_INDEX
      isoformLog: isoform/isoformLog
      seed: SEED
    out: [isoformTruth, fastq1, fastq2, fusionTruth] #  dip_gene_results, dip_iso_results, fus_gene_results, fus_iso_results, key1, key2]

  # archive:
  #   run: ../general_tools/tar_create.cwl
  #   in:
  #     fusion_log_file: fusion/fusLog
  #     fusion_FA_files: fusion/fusFA
  #     isoformTPM: isoform/isoformTPM
  #     fusionTPM: isoform/fusionTPM
  #     isoform_log_file: isoform/isoformLog
  #     dip_gene_results: reads/dip_gene_results
  #     dip_iso_results: reads/dip_iso_results
  #     fus_gene_results: reads/fus_gene_results
  #     fus_iso_results: reads/fus_iso_results
  #     key1: reads/key1
  #     key2: reads/key2
  #   out: [archive]
