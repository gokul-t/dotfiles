ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ansible-core \
      ca-certificates \
      git \
      python3-apt \
      sudo

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
