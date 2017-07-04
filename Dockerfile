FROM centos:centos6

RUN \
    yum update -y && \
    yum install wget -y && \
    yum install tar -y && \
    yum groupinstall "Development tools" -y

RUN useradd rdkit
USER rdkit

WORKDIR /home/rdkit

RUN wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
RUN /bin/bash ./Miniconda-latest-Linux-x86_64.sh -b -p /home/rdkit/miniconda

ENV PATH /home/rdkit/miniconda/bin:$PATH

RUN \
    conda update conda --yes --quiet && \
    conda install jinja2 conda-build anaconda-client --yes --quiet

RUN git clone https://github.com/rdkit/conda-rdkit

WORKDIR conda-rdkit


# on centos6 the max path length for a unix socket is 107 characters. this
# limit is exceeded when the postgresql build is located under the default
# filesystem path.
#
# with the current conda implementation (conda 4.2.13 - conda-build 2.0.10)
# the following $CONDA_BLD_PATH settings are sufficient to work around the
# problem.
#
# (as a side effect, packages will be found in /home/rdkit/bld/linux-64)
RUN mkdir /home/rdkit/bld
ENV CONDA_BLD_PATH /home/rdkit/bld

RUN conda build boost --quiet --no-anaconda-upload
RUN conda build nox --quiet --no-anaconda-upload
RUN conda build cairo_nox --quiet --no-anaconda-upload
RUN conda build cairocffi --quiet --no-anaconda-upload
RUN conda build eigen --quiet --no-anaconda-upload
RUN conda build rdkit --quiet --no-anaconda-upload
RUN conda create --use-local -y -n my-rdkit-env rdkit
RUN source activate my-rdkit-env
