#! /usr/bin/env python

import subprocess
import argparse
import os
import random
import shutil
import re
import time



########################
## Workflow functions
########################

def generateReads(model, isoV, simName, fusRef, fusV, simReads, dipGenome, otherReads, memory="2G", cores=1, disk="15G", seed=None):
	'''Generate fusion events.'''
	cmd = ' '.join(['rsem-simulate-reads', dipGenome, model, isoV, '0.066', str(otherReads), simName+'_diploid'])
	# if seed is specified, add seed as parameter to RSEM
	if isinstance(seed, (int, long)):
	    cmd = ' '.join([cmd, '--seed', str(seed)])
	print(cmd)
	subprocess.call(cmd, shell = True)
	cmd = ' '.join(['rsem-simulate-reads', fusRef, model, fusV, '0.066', str(int(simReads)), simName+'_fusions'])
	# if seed is specified, add seed as parameter to RSEM
	if isinstance(seed, (int, long)):
		cmd = ' '.join([cmd, '--seed', str(seed)])
	print(cmd)
	subprocess.call(cmd, shell = True)

	# TODO: Qualify fusion reads if they have sufficient coverage at breakpoint with certain features



def postProcessReads(simName, totalReads, simReads, write_each=True):
	'''Changes read names and merges read files.'''

	insertPosition = random.sample(xrange(int(totalReads)),int(simReads))
	insertPosition.sort(reverse=False)
	#	print '%s' % insertPosition

	diploidR1 = simName+'_diploid_1.fq'
	diploidR2 = simName+'_diploid_2.fq'
	fusionR1 = simName+'_fusions_1.fq'
	fusionR2 = simName+'_fusions_2.fq'

	if not os.path.isdir("tmp"):
		os.mkdir('tmp')

	combfq1 = simName+'_merged_1.fq'
	combfq2 = simName+'_merged_2.fq'

	if write_each:
		fusfq1 = simName+'_fusionsOnly_1.fq'
		fusfq2 = simName+'_fusionsOnly_2.fq'
		bkfq1 = simName+'_transcriptsOnly_1.fq'
		bkfq2 = simName+'_transcriptsOnly_2.fq'
	else:
		fusfq1 = None
		fusfq2 = None
		bkfq1 = None
		bkfq2 = None

	# Read1
	renameAndMerge(diploid = diploidR1, fusion = fusionR1, inserts = insertPosition,
	               fastqFileName = combfq1, fusfqName=fusfq1, bkfqName=bkfq1)
	cmd = ' '.join(['sort -T tmp -k1,1', combfq1, '| sed -e \'s/\\t/\\n/g\' - | gzip >', combfq1 + ".gz"])
	print(cmd)
	subprocess.call(cmd, shell = True)
	if write_each:
		# fusion
		cmd = ' '.join(['sort -T tmp -k1,1', fusfq1, '| sed -e \'s/\\t/\\n/g\' - | gzip >', fusfq1 + ".gz"])
		print(cmd)
		subprocess.call(cmd, shell = True)
		# transcript
		cmd = ' '.join(['sort -T tmp -k1,1', bkfq1, '| sed -e \'s/\\t/\\n/g\' - | gzip >', bkfq1 + ".gz"])
		print(cmd)
		subprocess.call(cmd, shell = True)

	# Read 2
	renameAndMerge(diploid = diploidR2, fusion = fusionR2, inserts = insertPosition,
	               fastqFileName = combfq2, fusfqName=fusfq2, bkfqName=bkfq2)
	cmd = ' '.join(['sort -T tmp -k1,1', combfq2, '| sed -e \'s/\\t/\\n/g\' - | gzip >', combfq2 + ".gz"])
	print(cmd)
	subprocess.call(cmd, shell = True)
	if write_each:
		# fusion
		cmd = ' '.join(['sort -T tmp -k1,1', fusfq2, '| sed -e \'s/\\t/\\n/g\' - | gzip >', fusfq2 + ".gz"])
		print(cmd)
		subprocess.call(cmd, shell = True)
		# transcript
		cmd = ' '.join(['sort -T tmp -k1,1', bkfq2, '| sed -e \'s/\\t/\\n/g\' - | gzip >', bkfq2 + ".gz"])
		print(cmd)
		subprocess.call(cmd, shell = True)

	shutil.rmtree('tmp')



def makeIsoformsTruth(simName, memory="100M", cores=1, disk="50M"):
	'''Takes in RSEM isoforms.results file from diploid simulation.'''
	# Ensure haploid transcripts are ordered for parsing next
	cmd = ' '.join(['sort', simName+'_diploid.sim.isoforms.results >', simName+'_diploid.sim.isoforms.results_sorted'])
	print(cmd)
	subprocess.call(cmd, shell = True)

	truthFH = open(simName+'_isoforms_truth.txt', 'w')
	with open(simName+'_diploid.sim.isoforms.results_sorted', 'r') as rsem:
		line1 = None
		for line in rsem:
			if not line.startswith('ENST'): continue
			if line1 is None:
				line1 = line
			else:
				# check that transcript ids match
				line1v = line1.strip().split()
				line2v = line.strip().split()
				if not line1v[0].split('-')[0] == line2v[0].split('-')[0]:
					print('Line matching off %s %s' % (line1v[0], line2v[0]))
					break
				else:
					# Adds TPM values for each haploid transcript
					summedTPM = float(line1v[5]) + float(line2v[5])
					truthFH.write('%s\t%f\n' % (line1v[0].split('-')[0], summedTPM))
				line1 = None
	truthFH.close()


def makeFusionTruth(simName, bedpe):
	'''
	Takes in RSEM fusion isoforms.results file from simulation and
	bedpe of events to create a single truth bedpe file
	'''
	bedpe_dat = dict()
	with open(bedpe, 'r') as bpfh:
		for line in bpfh:
			line_dat =  line.strip().split()
			# rename contigs so hap1, hap2 are not included
			line_dat[0] = line_dat[0].split('-')[0]
			line_dat[3] = line_dat[3].split('-')[0]
			# rename fusion name so hap1, hap2 are not included
			thx1, thx2 = line_dat[6].split("--")
			tx1, hap1 = thx1.split("-")
			tx2, hap2 = thx1.split("-")
			fus_name  = tx1 + "--" + tx2
			line_dat[6] = fus_name
			if fus_name not in bedpe_dat:
				bedpe_dat[fus_name] = '\t'.join(list(map(str, line_dat)))

	bedpeFH = open(simName+'_fusions_truth.bedpe', 'w')
	with open(simName+'_fusions.sim.isoforms.results', 'r') as rsem:
		for line in rsem:
			if line.startswith('transcript_id'): continue
			line1v = line.strip().split()
			thx1, thx2 = line1v[0].split("--")
			tx1, hap1 = thx1.split("-")
			tx2, hap2 = thx1.split("-")
			fus_name  = tx1 + "--" + tx2
			bedpeFH.write('%s\t%f\n' % (bedpe_dat[fus_name], float(line1v[5])))
	bedpeFH.close()


###############
# Other functions
###############

def renameAndMerge(diploid, fusion, inserts, fastqFileName, fusfqName=None, bkfqName=None):

	fqFH = open(fastqFileName, 'w')
	keyFH = open(fastqFileName + "_key.txt", 'w')

	if fusfqName:
		fusfqFH = open(fusfqName, 'w')
		fuskeyFH = open(fusfqName + "_key.txt", 'w')

	if bkfqName:
		bkfqFH = open(bkfqName, 'w')
		bkkeyFH = open(bkfqName + "_key.txt", 'w')

	# Write out fusion reads with new numbers
	iC = 0 # inserts counter
	read = ''
	if fusion:
		with open(fusion, 'r') as fusionFH:
			lC = 0
			for line in fusionFH:
				if lC == 0:
					header = '\t'.join([str(inserts[iC]),line.strip()])
					read = '@'+str(inserts[iC])
					iC += 1
				elif lC % 4 == 0 and lC > 0:
					writeFastQ(header, read, keyFileHandle=keyFH, fastqFileHandle=fqFH)
					if fusfqName:
						writeFastQ(header, read, keyFileHandle=fuskeyFH, fastqFileHandle=fusfqFH)
					read = '@'+str(inserts[iC])
					header = '\t'.join([str(inserts[iC]),line.strip()])
					iC += 1
				else:
					tmp = '\t'.join([read, line.strip()])
					read = tmp
				lC +=1
			writeFastQ(header, read, keyFileHandle=keyFH, fastqFileHandle=fqFH)
			if fusfqName:
				writeFastQ(header, read, keyFileHandle=fuskeyFH, fastqFileHandle=fusfqFH)


	# Write out regular reads with new numbers
	rC = 0 # read counter
	read = ''
	lC = 0 # line counter
	iC = 0 # inserts counter
	if diploid:
		with open(diploid, 'r') as diploidFH:
			for line in diploidFH:
				# skip read numbers that were already assigned to fusion reads
				if iC < len(inserts):
					while rC == inserts[iC]:
						rC += 1
						iC += 1
						if iC >= len(inserts): break
				# print reads with new numbers
				if lC % 4 == 0:
					if lC > 0:
						writeFastQ(header, read, keyFileHandle=keyFH, fastqFileHandle=fqFH)
						if bkfqName:
							writeFastQ(header, read, keyFileHandle=bkkeyFH, fastqFileHandle=bkfqFH)
					header = '\t'.join([str(rC),line.strip()])
					read = '@'+str(rC)
					rC += 1
				else:
					tmp = '\t'.join([read, line.strip()])
					read = tmp
				lC +=1
			# print the last read
			writeFastQ(header, read, keyFileHandle=keyFH, fastqFileHandle=fqFH)
			if bkfqName:
				writeFastQ(header, read, keyFileHandle=bkkeyFH, fastqFileHandle=bkfqFH)

	# close the FHs
	keyFH.close()
	fqFH.close()
	if fusfqName:
		fusfqFH.close()
	if bkfqName:
		bkfqFH.close()



def writeFastQ(header, readString, keyFileHandle, fastqFileHandle):
	keyFileHandle.write(header+'\n')
	fastqFileHandle.write(readString+'\n')


def parseIsoformLog(isoformLog):
	with open(isoformLog) as logFH:
		for line in logFH:
			m = re.search(".*fusion.*: ([0-9]+).*",line)
			if m:
				numSimReads = int(m.group(1))
				return numSimReads


if __name__=="__main__":

	parser = argparse.ArgumentParser("Runs workflow to generate fusion reads files.")
	parser.add_argument('--totalReads', default=5e6, help='Total number of reads to generate.', type=int, required=False)
	#    parser.add_argument('--numSimReads', default=5e5, help='Total number of simulated reads to generate.', type=int, required=False)
	parser.add_argument("--simName", help="Prefix for the simulation filenames.", default='testSimulation', required=False)
	parser.add_argument("--RSEMmodel", help="Model file from RSEM alignment.", required=True)
	parser.add_argument("--isoformTPM", help="File of isoform TPM values to simulate.", required=True)
	parser.add_argument("--fusionTPM", help="File of fusion TPM values to simulate.", required=True)
	parser.add_argument("--bedpe", help="File of bedpe fusions.", required=True)
	parser.add_argument("--fusRef", help="Path to fusion RSEM-format reference.", required=True)
	parser.add_argument("--dipGenome", help="RSEM reference name for diploid genome.", required=True)
	parser.add_argument("--isoformLog", help="Log file from modify isoforms step.", required=True)
	parser.add_argument("--seed", help="Seed number to use for RSEM read simulation.", type=int, required=False, default = None)
	parser.add_argument('--write_each', action='store_true', help='Additionally write FASTQs for both fusions and background transcripts.')
	args = parser.parse_args()

	# set seed to seed arument
	if isinstance(args.seed, (int, long)):
			random.seed(args.seed)

	## Wrap jobs
	numSimReads=parseIsoformLog(isoformLog=args.isoformLog)
	generateReads(model=args.RSEMmodel, isoV=args.isoformTPM, simName=args.simName, fusRef=args.fusRef, fusV=args.fusionTPM, simReads=numSimReads, dipGenome=args.dipGenome, otherReads=args.totalReads-numSimReads, seed=args.seed)
	postProcessReads(simName=args.simName, totalReads=args.totalReads, simReads=numSimReads, write_each=args.write_each)
	makeIsoformsTruth(simName=args.simName)
	makeFusionTruth(simName=args.simName, bedpe=args.bedpe)
