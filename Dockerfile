ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional applications
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
&& apt-get install -y curl build-essential \
        ca-certificates \
        \
        # .NET dependencies
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu70 \
        libssl3 \
        libstdc++6 \
        zlib1g \
&& rm -rf /var/lib/apt/lists/*

# Install .NET
ENV DOTNET_VERSION=7.0.0

RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='f4a6e9d5fec7d390c791f5ddaa0fcda386a7ec36fe2dbaa6acb3bdad38393ca1f9d984dd577a081920c3cae3d511090a2f2723cc5a79815309f344b8ccce6488' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install .NET Kernel
RUN dotnet interactive jupyter install

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
&& source "$HOME/.cargo/env"

# Install rustlang kernel
RUN conda install -y -c conda-forge nb_conda_kernels \
&& cargo install evcxr_jupyter \
&& evcxr_jupyter --install

