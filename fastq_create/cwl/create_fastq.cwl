#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
baseCommand: [generate_reads.py]

doc: "Generate FastQ reads files"

hints:
  DockerRequirement:
    dockerPull: andrewelambsage/rnaseqsim

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin:
    ramMin:

inputs:

  simName:
    type: string
    inputBinding:
      position: 1
      prefix: --simName

  RSEMmodel:
    type: File
    inputBinding:
      position: 1
      prefix: --RSEMmodel

  isoformTPM:
    type: File
    inputBinding:
      position: 1
      prefix: --isoformTPM

  fusionTPM:
    type: File
    inputBinding:
      position: 1
      prefix: --fusionTPM

  fusion_bedpe:
    type: File
    inputBinding:
      position: 1
      prefix: --bedpe

  totalReads:
    type: int
    inputBinding:
      position: 1
      prefix: --totalReads
      valueFrom: $(inputs.totalReads * 1000000)

  fusRef:
    type: File
    inputBinding:
      position: 1
      prefix: --fusRef
      valueFrom: $(inputs.fusRef.dirname + "/" + inputs.fusRef.nameroot)

  dipGenome:
    type: Directory
    inputBinding:
      position: 1
      prefix: --dipGenome
      valueFrom: $(inputs.dipGenome.path)

  isoformLog:
    type: File
    inputBinding:
      position: 1
      prefix: --isoformLog

  seed:
    type: int?
    inputBinding:
      position: 1
      prefix: --seed
    default: 19

outputs:

  fastq1:
    type: File
    outputBinding:
      glob: $(inputs.simName + "_mergeSort_1.fq.gz")

  fastq2:
    type: File
    outputBinding:
      glob: $(inputs.simName + "_mergeSort_2.fq.gz")

  isoformTruth:
    type: File
    outputBinding:
      glob: $(inputs.simName + "_isoforms_truth.txt")

  fusionTruth:
    type: File
    outputBinding:
      glob: $(inputs.simName + "_fusions_truth.bedpe")

