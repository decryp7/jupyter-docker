ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

# Install rustlang kernel
RUN apt-get update && \
apt-get install -y curl && \
curl https://sh.rustup.rs -sSf | sh sh -s -- -y

# Install additional kernels

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}