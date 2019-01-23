#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

baseCommand: [tar, cvzfh]

doc: "command line: tar"

inputs:

  out_filename:
    type: string
    inputBinding:
      position: 1

  input_dir:
    type: Directory
    inputBinding:
      position: 2

outputs:

  archive:
    type: File
    outputBinding:
      glob: $(inputs.out_filename)
