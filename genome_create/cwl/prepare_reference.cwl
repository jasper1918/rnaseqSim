#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [rsem-prepare-reference, --star]

doc: "Create diploid reference files"

hints:
  DockerRequirement:
    dockerPull: andrewlambsage/rnaseqsim:gw

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: "$(inputs.ref_name_dir)"
        writable: true
        entry: "$({class: 'Directory', listing: []})"

inputs:

  input_gtf:
    type: File
    inputBinding:
      position: 1
      prefix: --gtf

  num_cores:
    type: int
    inputBinding:
      position: 2
      prefix: --num-threads

  input_fasta:
    type: File
    inputBinding:
      position: 3

  ref_name_dir:
    type: string
    default: RSEM_INDEX
    doc: |
      Folder name where all rsem reference files will be saved

  ref_name:
    type: string
    inputBinding:
      position: 3
      valueFrom: $(inputs.ref_name_dir + "/" + self)


outputs:

  index_dir:
    type: Directory
    outputBinding:
      glob: "$(inputs.ref_name_dir)"
