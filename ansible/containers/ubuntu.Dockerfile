FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ansible-core \
      ca-certificates \
      curl \
      git \
      fontconfig \
      python3-apt \
      sudo \
      stow \
      unzip

WORKDIR /workspace
COPY . /workspace

ENV DOTFILES_ANSIBLE_EXTRA_VARS='{"dotfiles_install_snap_apps":false,"dotfiles_ubuntu_skip_packages":["adb","google-chrome-stable","gnome-shell-extension-manager","gnome-shell-extensions","gnome-tweaks","syncthing","vlc"],"dotfiles_stow_target":"/tmp/dotfiles-test-home"}'

ENV DOTFILES_POST_CHECK=ansible/containers/verify-workstation.sh

CMD ["bash", "ansible/containers/test-provisioning.sh"]
