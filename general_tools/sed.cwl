#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

baseCommand: [sed]

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement


inputs:

  input:
    type: File
    inputBinding:
      position: 1

  n:
    type: string
    inputBinding:
      position: 0
      prefix: -n

outputs:

  output:
    type: int?
