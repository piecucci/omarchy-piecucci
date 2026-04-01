#!/bin/bash

# Configuration for passwordless omarchy-update
echo "${USER} ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/pacman-key, /usr/bin/fwupdmgr, /usr/bin/systemctl, /usr/bin/btrfs, /usr/bin/snapper, /usr/bin/docker, /usr/bin/cp, /usr/bin/rm, /usr/bin/mv, /usr/bin/mkdir, /usr/bin/chmod, /usr/bin/chown, /usr/bin/tee, /usr/bin/sed, /usr/bin/swapoff, /usr/bin/swapon, /usr/bin/cryptsetup, /usr/bin/efibootmgr, /usr/local/bin/mkinitcpio, /usr/bin/modprobe, /usr/bin/plymouth-set-default-theme, /usr/bin/updatedb, /usr/bin/usermod, /usr/bin/timedatectl, /usr/bin/tailscale, /usr/bin/asdcontrol, /usr/bin/sudo -v, /usr/bin/sh /dev/stdin" | sudo tee /etc/sudoers.d/99-omarchy-update >/dev/null
sudo chmod 440 /etc/sudoers.d/99-omarchy-update
