ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional kernels
RUN pip install -r requirements.txt

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}