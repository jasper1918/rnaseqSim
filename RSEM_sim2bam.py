#/usr/bin python

import argparse
import gzip
import re
import os
import sys

def main():
	usage=""
	parser = argparse.ArgumentParser(description="Parameters:", epilog=usage)
	parser.add_argument('-i','--isoforms', type=str, required=True, help="Isoforms.results.file")
	parser.add_argument('-fq1','--fastq1', type=str, required=True, help="Read 1 fastq")
	parser.add_argument('-fq2','--fastq2', type=str, required=True, help="Read 2 fastq")
	parser.add_argument('-k', '--key', type=str, required=True, help="Fastq header key")
	parser.add_argument('-o', '--output_prefix',type=str, required=True, help="BAM output prefix")
	args=parser.parse_args()

	transcript_map = read_isoforms_results(args.isoforms)
	key_map = read_key(args.key)
	createBAM(transcript_map, key_map, args.fastq1, args.fastq2, args.output_prefix)


def read_isoforms_results(file):
	transcripts = dict()
	fh = open(file, "r")
	index=-1
	for line in fh.readlines():
		line=line.rstrip()
		parts = line.split("\t")
		transcripts[index]=parts[0]
		index = index + 1
	fh.close
	return transcripts	

def read_key(file):
	key_map = dict()
	fh = open(file, "r")
	for line in fh.readlines():
		line=line.rstrip()
		parts = line.split("\t")
		key_map[parts[0]]=parts[1]
	fh.close
	return key_map

def createBAM(transcripts, key, fq1, fq2, out):
	#gre = re.compile(".gz$")
	#if gre.match(fq1):
	#	fh1=gzip.open(fq1,"rb")
	#else:
	#	fh1=open(fq1,"r")	
	#	
	#if gre.match(fq2):
	#	fh2=gzip.open(fq2,"rb")
	#else:
	#	fh2=open(fq2,"r")
	base1, ext1 = os.path.splitext(fq1)
	fh1 = gzip.open(fq1,"rb") if ext1==".gz" else open(fq1, 'r')
	base2, ext2 = os.path.splitext(fq2)
	fh2 = gzip.open(fq2,"rb") if ext2==".gz" else open(fq2, 'r')
	ofh = open("{}.truth.diploid.sam".format(out), "w+")
	
	for line in fh1:
		header1 = line.replace("/1","").rstrip()
		sequence1 = fh1.readline().rstrip()
		filler1 = fh1.readline().rstrip()
		quality1 = fh1.readline().rstrip()

		header2 = fh2.readline().rstrip().replace("/2","").rstrip()
		sequence2 = fh2.readline().rstrip()
		filler2 = fh2.readline().rstrip()
		quality2 = fh2.readline().rstrip()
	
		if(header1!=header2):
			sys.exit("Pair mismatch: {} and {}".format(header1,header2))		
		
		len1 = len(sequence1)
		len2 = len(sequence2)
		
		readname = header1[1:]
		qname = key[readname].replace("@","").replace("/1","")
		name_parts = qname.split("_")
		read1flag = 83
		read2flag = 163
		rname = transcripts[int(name_parts[2])]
		pos1=int(name_parts[3])+1
		pos2=pos1+len1+int(name_parts[4])
		cigar1 = "{}M".format(len1)
		cigar2 = "{}M".format(len2)
		mapq = 255
		tlen = len1+len2+int(name_parts[4])
		tags = "NH:i:1 HI:i:1"
		entry1 = "\t".join(map(str,[qname,read1flag,rname,pos1,mapq,cigar1,'=',pos2,tlen,sequence1,quality1,tags]))
		entry2 = "\t".join(map(str,[qname,read2flag,rname,pos2,mapq,cigar2,'=',pos1,-1*tlen,sequence2,quality2,tags]))
		ofh.write("{}\n{}\n".format(entry1,entry2))

	fh1.close()
	fh2.close()
	ofh.close()
	
if __name__=="__main__":
	main()
