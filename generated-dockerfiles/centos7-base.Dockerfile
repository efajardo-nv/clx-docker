# RAPIDS Dockerfile for centos7 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=centos7
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=gpuci/miniconda-cuda

FROM ${FROM_IMAGE}:${CUDA_VER}-base-${LINUX_VER}

ARG CUDA_VER
ARG PYTHON_VER=3.7

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER=0.15*

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
COPY start_jupyter.sh nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/
COPY gpuci_conda_retry .condarc /opt/conda/bin/
COPY .condarc /opt/conda/

COPY libm.so.6 ${GCC7_DIR}/lib64

RUN conda create -n rapids


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN source activate rapids && gpuci_conda_retry install -c pytorch python=${PYTHON_VER} clx=${RAPIDS_VER} rapids=${RAPIDS_VER} cudatoolkit=${CUDA_VER} 


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

COPY .run_in_rapids.sh /.run_in_rapids
RUN chmod +x /usr/bin/tini && \
    echo "source activate rapids" >> ~/.bashrc
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]