#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

baseCommand: [sed]

doc: "Replace names using an expression"

stdout: $(inputs.out_filename)

inputs:

  input_string:
    type: string
    inputBinding:
      position: 1
      prefix: -e

  input_file:
    type: File
    inputBinding:
      position: 2

  out_filename:
    type: string

outputs:

  output_file:
    type: stdout
