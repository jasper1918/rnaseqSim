#!/usr/bin/env cwl-runner
#
# Authors: Andrew Lamb

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

baseCommand: [tar, cvzfh]
# strip assumes /var/lib/cwl/stg*/file.txt

doc: "command line: tar"

inputs:

  out_filename:
    type: string
    inputBinding:
      position: 1

  input_files:
    type: File[]
    inputBinding:
      position: 2


outputs:

  archive:
    type: File
    outputBinding:
      glob: $(inputs.out_filename)
