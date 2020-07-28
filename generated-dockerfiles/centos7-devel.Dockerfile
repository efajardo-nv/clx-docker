# RAPIDS CLX Dockerfile for centos7 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=centos7
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=gpuci/miniconda-cuda

FROM ${FROM_IMAGE}:${CUDA_VER}-devel-${LINUX_VER}

ARG CUDA_VER
ARG PYTHON_VER=3.7

ARG PARALLEL_LEVEL=16

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR} && \
    cd ${RAPIDS_DIR} && \
    git clone https://github.com/rapidsai/clx.git

RUN conda env create --name rapids --file ${RAPIDS_DIR}/clx/conda/environments/clx_dev_cuda${CUDA_VER}.yml python=${PYTHON_VER}

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/conda/envs/rapids/lib
RUN cd ${RAPIDS_DIR}/clx && \
  source activate rapids && \
  ./build.sh


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

COPY .run_in_rapids.sh /.run_in_rapids
RUN chmod +x /usr/bin/tini && \
    echo "source activate rapids" >> ~/.bashrc
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]