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

# Add .cargo/bin to PATH
ENV PATH="/home/jovyan/.cargo/bin:${PATH}"

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

# Install .NET
ENV DOTNET_VERSION=6.0.0

RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='6a1ae878efdc9f654e1914b0753b710c3780b646ac160fb5a68850b2fd1101675dc71e015dbbea6b4fcf1edac0822d3f7d470e9ed533dd81d0cfbcbbb1745c6c' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Install rustlang kernel
#RUN conda install -y -c conda-forge nb_conda_kernels \
#&& cargo install evcxr_jupyter \
#&& evcxr_jupyter --install

# Install additional kernels

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
&& source "$HOME/.cargo/env" \
&& cargo --help
