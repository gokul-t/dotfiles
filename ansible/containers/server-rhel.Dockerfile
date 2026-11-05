ARG BASE_IMAGE=rockylinux:9
FROM ${BASE_IMAGE}

ENV ANSIBLE_LOCAL_TEMP=/tmp/ansible-local

RUN dnf install -y --allowerasing \
      ansible-core \
      ca-certificates \
      curl \
      git \
      sudo \
      unzip \
    && dnf clean all

RUN useradd -m -s /bin/bash dotuser \
    && echo "dotuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dotuser \
    && chmod 0440 /etc/sudoers.d/dotuser

WORKDIR /workspace
COPY --chown=dotuser:dotuser . /workspace

USER dotuser
ENV HOME=/home/dotuser \
    DOTFILES_ANSIBLE_EXTRA_VARS='{"dotfiles_profile":"server"}' \
    DOTFILES_POST_CHECK=ansible/containers/verify-server.sh

CMD ["bash", "ansible/containers/test-provisioning.sh"]
