# RAPIDS Dockerfile for centos7 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=centos7
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=gpuci/miniconda-cuda

FROM ${FROM_IMAGE}:${CUDA_VER}-devel-${LINUX_VER}

ARG CUDA_VER
ARG PYTHON_VER=3.7

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER=0.15*

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR} && \
    cd ${RAPIDS_DIR} && \
    git clone https://github.com/rapidsai/clx.git

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
RUN mkdir -p ${RAPIDS_DIR}/notebooks ${GCC7_DIR}/lib64
COPY start_jupyter.sh nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/
COPY notebooks/ ${RAPIDS_DIR}/notebooks/
COPY gpuci_conda_retry .condarc /opt/conda/bin/
COPY .condarc /opt/conda/

COPY libm.so.6 ${GCC7_DIR}/lib64

RUN conda create -n rapids

RUN source activate rapids && gpuci_conda_retry install -c pytorch -c gwerbin \
    "clx=${RAPIDS_VER}" \
    "numpy>=1.17.3,<1.19.0" \
    "python-confluent-kafka" \
    "transformers" \
    "seqeval" \
    "python-whois" \
    "seaborn" \
    "requests" \
    "s3fs" \
    "ipython" \
    "ipywidgets" \
    "jupyterlab" \
    "matplotlib"

RUN source activate rapids \
    && pip install "git+https://github.com/dask/distributed.git" --upgrade --no-deps \
    && pip install "git+https://github.com/dask/dask.git" --upgrade --no-deps \
    && pip install "git+https://github.com/rapidsai/cudatashader.git"


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
WORKDIR ${RAPIDS_DIR}/clx/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786

COPY .start_jupyter_run_in_rapids.sh /.run_in_rapids


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

RUN chmod +x /usr/bin/tini && \
    echo "source activate rapids" >> ~/.bashrc
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]