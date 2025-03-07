FROM quay.io/jupyter/base-notebook:latest

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
	build-essential \
  git

# Install .NET CLI dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libc6 \
  libgcc1 \
  libgssapi-krb5-2 \
  libicu74 \
  libssl3 \
  libstdc++6 \
  zlib1g \
  openjdk-11-jre \
  && rm -rf /var/lib/apt/lists/*

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
&& apt-get install -y nodejs \
&& npm install -g itypescript

# Install the latest LTS dotnet SDK
RUN curl -L https://dot.net/v1/dotnet-install.sh | bash -e -s -- --install-dir /usr/share/dotnet --channel 9.0 \
  && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Trigger first run experience by running arbitrary command
RUN dotnet help

# Install golang
COPY --from=mirror.gcr.io/golang:1 /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version

RUN chown -R ${NB_UID} ${HOME}

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install additional python modules
COPY requirements.txt ${HOME}/requirements.txt
RUN pip install -r requirements.txt \
&& rm requirements.txt

# Install additional extensions
RUN conda install -c conda-forge jupyterlab-git

# Install itypescript kernel
RUN its --install=local

# Install golang kernel
ENV PATH="$HOME/go/bin:$PATH"
RUN go install github.com/gopherdata/gophernotes@v0.7.5 \
&& mkdir -p ~/.local/share/jupyter/kernels/gophernotes \
&& cd ~/.local/share/jupyter/kernels/gophernotes \
&& cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/*  "." \
&& chmod +w ./kernel.json # in case copied kernel.json has no write permission \
&& sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

# Install C++ kernel
RUN conda install xeus-cling -c conda-forge \
&& conda install xeus -c conda-forge

# Install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="$HOME/.cargo/bin:$PATH"

# Install rustlang kernel
RUN conda install -y -c conda-forge nb_conda_kernels \
&& cargo install evcxr_jupyter \
&& evcxr_jupyter --install

# Install dotnet kernel
ENV PATH="$HOME/.dotnet/tools:$PATH"
RUN dotnet tool install -g Microsoft.dotnet-interactive \
&& dotnet interactive jupyter install

# Install Kotlin kernel
ENV PATH="/usr/lib/jvm/java-11-openjdk-amd64/jre/bin:$PATH"
RUN conda install kotlin-jupyter-kernel -c jetbrains

WORKDIR ${HOME}