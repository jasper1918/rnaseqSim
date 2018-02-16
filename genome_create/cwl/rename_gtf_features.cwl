#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

baseCommand: [make_haploid_gtf.py]

doc: "Changing gene, transcript, and chromosome names in GTF"

hints:
  DockerRequirement:
    dockerPull: andrewlambsage/rnaseqsim:gw

stdout: $(inputs.out_filename)


inputs:

  input_string:
    type: string
    inputBinding:
      position: 1
      prefix: --suffix


  input_gtf:
    type: File
    inputBinding:
      position: 2
      prefix: --GTF

  out_filename:
      type: string


outputs:

  output_gtf:
    type: stdout
