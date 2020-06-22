ARG CUDA_VERSION
FROM nvidia/cuda:${CUDA_VERSION}-cudnn7-devel-ubuntu16.04

RUN apt-get update && apt-get install -y software-properties-common python-software-properties

RUN add-apt-repository ppa:ubuntugis/ppa && \
    apt-get update && \
    apt-get install -y wget=1.* git=1:2.* python-protobuf=2.* python3-tk=3.* \
                       jq=1.5* \
                       build-essential libsqlite3-dev=3.11.* zlib1g-dev=1:1.2.* \
                       libopencv-dev=2.4.* python-opencv=2.4.* unzip curl && \
    apt-get autoremove && apt-get autoclean && apt-get clean

# See https://github.com/mapbox/rasterio/issues/1289
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# Install Python 3.6
RUN wget -q -O ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh
ENV PATH /opt/conda/bin:$PATH
ENV LD_LIBRARY_PATH /opt/conda/lib/:$LD_LIBRARY_PATH
RUN conda install -y python=3.6
RUN python -m pip install --upgrade pip

# ?
RUN conda install -y -c conda-forge gdal=3.0.4

# Setup GDAL_DATA directory, rasterio needs it.
ENV GDAL_DATA=/opt/conda/lib/python3.6/site-packages/rasterio/gdal_data/

WORKDIR /opt/src/
ENV PYTHONPATH=/opt/src:$PYTHONPATH

# COPY ./rastervision_pipeline/requirements.txt /opt/src/requirements.txt
# RUN pip install -r requirements.txt
# COPY ./rastervision_aws_s3/requirements.txt /opt/src/requirements.txt
# RUN pip install -r requirements.txt

COPY ./requirements-dev.txt /opt/src/requirements-dev.txt
RUN pip install -r requirements-dev.txt

COPY ./rastervision_pipeline/ /opt/src/rastervision_pipeline/
RUN cd /opt/src/rastervision_pipeline/ && pip install .
COPY ./rastervision_aws_s3/ /opt/src/rastervision_aws_s3/
RUN cd /opt/src/rastervision_aws_s3/ && pip install .
COPY ./rastervision_aws_batch/ /opt/src/rastervision_aws_batch/
RUN cd /opt/src/rastervision_aws_batch/ && pip install .

COPY ./rastervision_core/ /opt/src/rastervision_core/
RUN cd /opt/src/rastervision_core/ && pip install .

# TODO make a release for this and move into requirements.txt
RUN pip install git+git://github.com/azavea/mask-to-polygons@f1d0b623c648ba7ccb1839f74201c2b57229b006

COPY ./rastervision_pytorch_learner/ /opt/src/rastervision_pytorch_learner/
RUN cd /opt/src/rastervision_pytorch_learner/ && pip install .
COPY ./rastervision_pytorch_backend/ /opt/src/rastervision_pytorch_backend/
RUN cd /opt/src/rastervision_pytorch_backend/ && pip install .
COPY ./rastervision_examples/ /opt/src/rastervision_examples/
RUN cd /opt/src/rastervision_examples/ && pip install .

COPY scripts /opt/src/scripts/

# Needed for click to work
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV PROJ_LIB /opt/conda/share/proj/
