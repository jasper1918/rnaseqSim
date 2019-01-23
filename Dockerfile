FROM ubuntu:16.04

RUN apt-get update
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -
RUN apt-get update
RUN apt-get -y install r-base git wget tar g++ make python python-pip zlib1g-dev git

RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('argparse')"
RUN Rscript -e "install.packages('data.table')"

RUN pip install argparse synapseclient numpy gffutils biopython

WORKDIR /opt

ENV NAMEH htslib
ENV NAME bcftools

RUN git clone https://github.com/samtools/htslib.git && \
    cd ${NAMEH} && \
    make -j 4 && \
    cd .. && \
    cp ./${NAMEH}/tabix /usr/local/bin/ && \
    cp ./${NAMEH}/bgzip /usr/local/bin/ && \
    cp ./${NAMEH}/htsfile /usr/local/bin/ && \
    strip /usr/local/bin/tabix; true && \
    strip /usr/local/bin/bgzip; true && \
    strip /usr/local/bin/htsfile; true && \

RUN git clone https://github.com/samtools/bcftools.git && \
    cd ${NAME} && \
    make -j 4 && \
    cp ./${NAME} /usr/local/bin/ && \
    cp ./plugins/*.so /usr/local/bin/ && \
    cd .. && \
    strip /usr/local/bin/${NAME}; true && \
    rm -rf ./${NAMEH}/ && \
    rm -rf ./${NAME}/ && \
    rm -rf ./${NAMEH}

RUN wget https://github.com/deweylab/RSEM/archive/v1.3.1.tar.gz && \
    tar -zxvf v1.3.1.tar.gz && \
    cd RSEM-1.3.1/ && \
    make && \
    make install

RUN wget https://github.com/alexdobin/STAR/archive/STAR_2.6.1d.tar.gz && \
    tar -zxvf STAR_2.6.1d.tar.gz && \
    cp /opt/STAR-STAR_2.6.1d/bin/Linux_x86_64/* /usr/local/bin

RUN git clone https://github.com/andrewelambsage/rnaseqSim/ && \
    chmod +x /opt/rnaseqSim/fusion_create/*.py* && \
    chmod +x /opt/rnaseqSim/model_isoforms/*.R && \
    chmod +x /opt/rnaseqSim/fastq_create/*.py && \
    chmod +x /opt/rnaseqSim/genome_create/*.py

ENV PATH /opt/rnaseqSim/fusion_create:$PATH
ENV PATH /opt/rnaseqSim/model_isoforms:$PATH
ENV PATH /opt/rnaseqSim/fastq_create:$PATH
ENV PATH /opt/rnaseqSim/genome_create:$PATH
