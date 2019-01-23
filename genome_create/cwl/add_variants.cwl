#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [bcftools, consensus]

doc: "Add variants to fasta files"
# http://samtools.github.io/bcftools/howtos/consensus-sequence.html

hints:
  DockerRequirement:
    dockerPull: andrewlambsage/rnaseqsim:gw

requirements:
  - class: InlineJavascriptRequirement

inputs:

  input_fasta:
    type: File
    inputBinding:
      position: 1
      prefix: -f

  output_fasta_name:
    type: string
    inputBinding:
      position: 2
      prefix: -o

  haplotype_which:
    type: string?
    inputBinding:
      position: 3
      prefix: -H
    default: "A"

  input_vcf:
    type: File
    inputBinding:
      position: 3
    secondaryFiles:
    - .tbi

outputs:

  output_fasta:
    type: File
    outputBinding:
      glob: $(inputs.output_fasta_name)
