#!/bin/bash
BC_FILES_BASE_DIR=~/benchmarks/openssh-portable/
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"sshd.bc openssh-sshd
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"scp.bc openssh-scp
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-agent.bc openssh-ssh-agent
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-add.bc openssh-ssh-add
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh.bc openssh-ssh
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-sk-helper.bc openssh-ssh-sk-helper
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-pkcs11-helper.bc openssh-ssh-pkcs11-helper
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"sftp.bc openssh-sftp
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"sftp-server.bc openssh-sftp-server
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-keygen.bc openssh-ssh-keygen
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-keyscan.bc openssh-ssh-keyscan
./run-eesi-wrapper.sh "$BC_FILES_BASE_DIR"ssh-keysign.bc openssh-ssh-keysign
