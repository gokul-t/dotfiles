ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Install basic prerequisites for bootstrap
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with passwordless sudo
RUN useradd -m -s /bin/bash dotuser && \
    echo "dotuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dotuser
WORKDIR /home/dotuser
