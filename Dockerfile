ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="decryp7 <decrypt@decryptology.net>"

USER root

# Install additional applications
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
&& apt-get install -y \
	wget \
	curl \
	build-essential \
&& wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y dotnet-sdk-7.0 \
&& rm -rf /var/lib/apt/lists/*

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install additional python modules
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt

# Install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="$HOME/.cargo/bin:${PATH}"

# Install rustlang kernel
RUN conda install -y -c conda-forge nb_conda_kernels \
&& cargo install evcxr_jupyter \
&& evcxr_jupyter --install

# Install dotnet kernel
RUN dotnet tool install -g Microsoft.dotnet-interactive \ 
&& dotnet interactive jupyter install