#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [bcftools, index, "-ft"]

doc: "Index VCF file"

hints:
  DockerRequirement:
    dockerPull: andrewlambsage/rnaseqsim:gw

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.input_vcf)

inputs:

  input_vcf:
    type: File
    inputBinding:
      position: 1

outputs:

  output_index:
    type: File
    outputBinding:
      glob: $(inputs.input_vcf.basename)
    secondaryFiles:
      - .tbi

arguments:
  - valueFrom: $(inputs.input_vcf.basename + ".tbi")
    position: 2
    prefix: -o
