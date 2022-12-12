ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional applications
RUN apt-get update && \
apt-get install -y curl && \
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

# Create conda env
RUN conda create --name evcxr

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "evcxr", "/bin/bash", "-c"]

# Install rustlang kernel
RUN conda activate evcxr && \
conda install -y -c conda-forge nb_conda_kernels && \
cargo install evcxr_jupyter && \
evcxr_jupyter --install

# Install additional kernels

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}