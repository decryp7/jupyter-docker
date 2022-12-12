FROM jupyter/base-notebook:ubuntu-22.04

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

WORKDIR ${HOME}

USER root

ENV \
  # Enable detection of running in a container
  DOTNET_RUNNING_IN_CONTAINER=true \
  # Enable correct mode for dotnet watch (only mode supported in a container)
  DOTNET_USE_POLLING_FILE_WATCHER=true \
  # Skip extraction of XML docs - generally not useful within an image/container - helps performance
  NUGET_XMLDOC_MODE=skip \
  # Opt out of telemetry until after we install jupyter when building the image, this prevents caching of machine id
  DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT=true

# Install additional applications
RUN apt-get update \
&& apt-get install -y \
	wget \
	curl \
	build-essential

# Install .NET CLI dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libc6 \
  libgcc1 \
  libgssapi-krb5-2 \
  libicu70 \
  libssl3 \
  libstdc++6 \
  zlib1g \
  && rm -rf /var/lib/apt/lists/*

# Install the appropriate dotnet SDK
ENV DOTNET_SDK_VERSION 7.0.100
RUN curl -L https://dot.net/v1/dotnet-install.sh | bash -e -s -- --install-dir /usr/share/dotnet --version $DOTNET_SDK_VERSION \
  && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Trigger first run experience by running arbitrary command
RUN dotnet help

RUN chown -R ${NB_UID} ${HOME}

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install additional python modules
COPY requirements.txt ${HOME}/requirements.txt
RUN pip install -r requirements.txt \
&& rm requirements.txt

# Install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="$HOME/.cargo/bin:$PATH"

# Install rustlang kernel
RUN conda install -y -c conda-forge nb_conda_kernels \
&& cargo install evcxr_jupyter \
&& evcxr_jupyter --install

# Install dotnet kernel
ENV PATH="$HOME/.dotnet/tools:$PATH"
RUN dotnet tool install -g Microsoft.dotnet-interactive --add-source "https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json" \
&& dotnet interactive jupyter install

WORKDIR ${HOME}