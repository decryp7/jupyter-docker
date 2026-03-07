FROM quay.io/jupyter/base-notebook:latest

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

ARG NB_USER=jovyan
ARG NB_UID=1000

ENV USER=${NB_USER} \
    NB_UID=${NB_UID} \
    HOME=/home/${NB_USER}

WORKDIR ${HOME}

USER root

ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT=true \
    DOTNET_ROOT=/usr/share/dotnet

# Base tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget \
      curl \
      build-essential \
      git \
      libc6 \
      libgcc-s1 \
      libgssapi-krb5-2 \
      libicu74 \
      libssl3 \
      libstdc++6 \
      zlib1g \
      openjdk-11-jre && \
    rm -rf /var/lib/apt/lists/*

# Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g itypescript && \
    rm -rf /var/lib/apt/lists/*

# Install current LTS .NET SDK
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --install-dir /usr/share/dotnet --channel LTS && \
    ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    dotnet --info && \
    dotnet --list-sdks

# Warm first-run cache
RUN dotnet help

# Go
COPY --from=mirror.gcr.io/golang:1 /usr/local/go/ /usr/local/go/
ENV PATH=/usr/local/go/bin:${PATH}
RUN go version

RUN chown -R ${NB_UID}:0 ${HOME}

USER ${NB_UID}

# Python requirements
COPY requirements.txt ${HOME}/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt

# JupyterLab Git extension
RUN conda install -y -c conda-forge jupyterlab-git

# TypeScript kernel
RUN its --install=local

# Go kernel
ENV PATH=${HOME}/go/bin:${PATH}
RUN go install github.com/gopherdata/gophernotes@v0.7.5 && \
    mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
    cd ~/.local/share/jupyter/kernels/gophernotes && \
    cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/* . && \
    chmod +w ./kernel.json && \
    sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

# C++ kernel
RUN conda install -y -c conda-forge xeus-cling xeus

# Rust + kernel
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH=${HOME}/.cargo/bin:${HOME}/.dotnet/tools:${PATH}
RUN conda install -y -c conda-forge nb_conda_kernels && \
    cargo install evcxr_jupyter && \
    evcxr_jupyter --install

# .NET kernel
RUN dotnet tool install --global Microsoft.dotnet-interactive && \
    ${HOME}/.dotnet/tools/dotnet-interactive jupyter install

# Kotlin kernel
ENV PATH=/usr/lib/jvm/java-11-openjdk-amd64/jre/bin:${PATH}
RUN conda install -y -c jetbrains kotlin-jupyter-kernel

WORKDIR ${HOME}