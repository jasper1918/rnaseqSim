#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [cat]

doc: "Combine files"

stdout: $(inputs.out_filename)

inputs:

  input_files:
    type: File[]
    inputBinding:
      position: 1

  out_filename:
    type: string

outputs:

  output_file:
    type: stdout
