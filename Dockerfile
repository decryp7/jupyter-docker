ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional applications
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
&& apt-get install -y \
	curl \
	build-essential \
	dotnet-sdk-7.0 \
&& rm -rf /var/lib/apt/lists/*

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
&& source "$HOME/.cargo/env" \
&& cargo --help

# Install rustlang kernel
RUN conda install -y -c conda-forge nb_conda_kernels \
&& cargo install evcxr_jupyter \
&& evcxr_jupyter --install

