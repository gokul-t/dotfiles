FROM fedora:44

ENV ANSIBLE_LOCAL_TEMP=/tmp/ansible-local

RUN dnf install -y \
      ansible-core \
      ca-certificates \
      curl \
      fontconfig \
      git \
      sudo \
      stow \
      unzip \
    && dnf clean all

WORKDIR /workspace
COPY . /workspace

ENV DOTFILES_ANSIBLE_EXTRA_VARS='{"dotfiles_install_flatpak_apps":false,"dotfiles_fedora_skip_packages":["code","google-chrome-stable","gnome-tweaks","yazi","starship","ghostty","syncthing","vlc"],"dotfiles_stow_target":"/tmp/dotfiles-test-home"}'

CMD ["bash", "ansible/containers/test-provisioning.sh"]
