#!/bin/bash
SSH_MASTER_USER="master"
SSH_MASTER_PASS="passward"
set -e

printf "\n\033[0;44m---> Creating SSH master user.\033[0m\n"

useradd -m -u 501 -d /home/"${SSH_MASTER_USER}" "${SSH_MASTER_USER}" -s /bin/bash
echo "${SSH_MASTER_USER}:${SSH_MASTER_PASS}" | chpasswd
echo 'PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin"' >>/home/"${SSH_MASTER_USER}"/.profile
echo "${SSH_MASTER_USER} ALL=NOPASSWD: ALL" >>/etc/sudoers
mkdir -p /home/"${SSH_MASTER_USER}/.pip"
mv /pip.conf /home/"${SSH_MASTER_USER}/.pip"
