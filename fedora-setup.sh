# Avoid slowing down boot if we have NICs in a direct-attach loop.
# Might require disabling systemd equivalent on server version.
# sudo systemctl disable NetworkManager-wait-online.service 

# Dev environment
sudo dnf -y install \
	intel-one-mono-fonts \
	alacritty \
	helix

# System packages, kernel dev, hardware, virtualization
sudo dnf -y install \
	git-lfs \
	kernel-devel \
	perf \
	cmake \
	lshw \
	htop \
	qemu-system-riscv \
	gcc-riscv64-linux-gnu \
	numactl \
	numactl-devel \
	dpdk-devel \
	dpdk-tools \
	@virtualization

# U-Boot
sudo dnf -y install \
	openssl-devel-engine \
	gnutls-devel

# FreeBSD dev
sudo dnf -y install \
	lld \
	libarchive-devel \
	bzip2-devel \
	patch

# Unity dev
sudo dnf -y install \
	openssl \
	openssl-libs \
	GConf2

# Languages, compilers, linkers, LSPs
sudo dnf -y install \
	clang \
	clang-tools-extra \
	mold \
	rustup

# Install Rust nightly
rustup-init -y \
	--default-host x86_64-unknown-linux-gnu \
	--default-toolchain nightly
	--no-modify-path
. "$HOME/.cargo/env"

# Get rid of things we don't need
sudo dnf group remove -y \
	libreoffice

# Admin, util, miscallaneous 
sudo dnf -y install \
	pass \
	just \
	pre-commit \
	cloc

