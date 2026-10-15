#!/usr/bin/env bash

# Run as your normal user; individual system changes use sudo.
# Reruns ensure tools are present without reinstalling Zed or updating Rust.
set -euo pipefail

# Avoid slowing down boot if we have NICs in a direct-attach loop.
# Might require disabling systemd equivalent on server version.
# sudo systemctl disable NetworkManager-wait-online.service 

# Dev environment
sudo dnf -y install \
	curl \
	ca-certificates \
	intel-one-mono-fonts \
	alacritty \
	helix

# Zed IDE
if ! command -v zed >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/zed" ]; then
    (
        setup_zed_tmp=$(mktemp -d)
        trap 'rm -rf -- "$setup_zed_tmp"' EXIT
        curl -fL --retry 3 https://zed.dev/install.sh -o "$setup_zed_tmp/install.sh"
        sh "$setup_zed_tmp/install.sh"
    )
else
    printf '%s\n' 'Zed is already installed; skipping.'
fi

# System packages, kernel dev, hardware, virtualization
sudo dnf -y install \
	git-lfs \
	kernel-devel \
	perf \
	cmake \
	lshw \
	htop \
	qemu-system-riscv \
	qemu-system-aarch64 \
	gcc-riscv64-linux-gnu \
	gcc-riscv32-linux-gnu \
	numactl \
	numactl-devel \
	dpdk-devel \
	dpdk-tools \
	dtc \
	@virtualization

# U-Boot
sudo dnf -y install \
	openssl-devel-engine \
	python3-devel \
	gnutls-devel \
	swig

# PCB
sudo dnf -y install \
	kicad

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

# Ensure Rust nightly is installed, preserving an existing default toolchain.
setup_cargo_home="${CARGO_HOME:-$HOME/.cargo}"
setup_rustup=$(command -v rustup || true)
if [ -z "$setup_rustup" ] && [ -x "$setup_cargo_home/bin/rustup" ]; then
    setup_rustup="$setup_cargo_home/bin/rustup"
fi
if [ -z "$setup_rustup" ]; then
    rustup-init -y --default-toolchain none --no-modify-path
    setup_rustup="$setup_cargo_home/bin/rustup"
fi
if [ -f "$setup_cargo_home/env" ]; then
    . "$setup_cargo_home/env"
fi
setup_toolchains=$("$setup_rustup" toolchain list)
if ! grep -Eq '^nightly(-[[:alpha:]]|[[:space:]]|$)' <<< "$setup_toolchains"; then
    "$setup_rustup" toolchain install --no-self-update nightly
fi
if ! "$setup_rustup" default >/dev/null 2>&1; then
    "$setup_rustup" default nightly
fi

# FPGA dev, SystemVerilog simulation, waveform viewers, serial tests
sudo dnf -y install \
	git \
	curl \
	wget \
	tar \
	gzip \
	unzip \
	patch \
	diffutils \
	gcc \
	gcc-c++ \
	make \
	autoconf \
	automake \
	libtool \
	m4 \
	pkgconf-pkg-config \
	gmp-devel \
	zlib-devel \
	libffi-devel \
	readline-devel \
	ncurses-devel \
	verilator \
	gtkwave \
	python3 \
	python3-pyserial \
	picocom \
	zlib-ng-compat-static \
	usbutils || exit 1

# slang-server: SystemVerilog language server, installed for the current user.
# https://github.com/hudson-trading/slang-server/releases
(
    slang_server_version=v0.3.0
    slang_server_install_dir="$HOME/.local/bin"
    if [ -x "$slang_server_install_dir/slang-server" ] && \
        slang_server_installed_version=$("$slang_server_install_dir/slang-server" --version 2>&1); then
        case "$slang_server_installed_version" in
            "slang-server version ${slang_server_version#v}"|"slang-server version ${slang_server_version#v}+")
                printf 'slang-server %s is already installed; skipping.\n' "$slang_server_version"
                exit 0
                ;;
        esac
    fi
    case "$(uname -m)" in
        x86_64)
            slang_server_arch=x64
            slang_server_sha256=29ad91f245f100337c35ce27dba711d5f0ea50ebc70e73c78e2b27400a87ae62
            ;;
        *)
            printf 'No slang-server release configured for architecture: %s\n' "$(uname -m)" >&2
            exit 1
            ;;
    esac
    slang_server_tmp=$(mktemp -d) || exit 1
    trap 'rm -rf -- "$slang_server_tmp"' EXIT
    slang_server_archive="slang-server-linux-${slang_server_arch}.tar.gz"
    curl -fL --retry 3 \
        "https://github.com/hudson-trading/slang-server/releases/download/${slang_server_version}/${slang_server_archive}" \
        -o "$slang_server_tmp/$slang_server_archive" || exit 1
    printf '%s  %s\n' "$slang_server_sha256" "$slang_server_tmp/$slang_server_archive" \
        | sha256sum --check --status || exit 1
    tar -xzf "$slang_server_tmp/$slang_server_archive" -C "$slang_server_tmp" || exit 1
    "$slang_server_tmp/slang-server" --version || exit 1
    install -d "$slang_server_install_dir" || exit 1
    install -m 0755 "$slang_server_tmp/slang-server" "$slang_server_install_dir/slang-server" || exit 1
    "$slang_server_install_dir/slang-server" --version
) || exit 1

# Get rid of things we don't need
sudo dnf -y remove 'libreoffice*'

# Admin, util, miscallaneous 
sudo dnf -y install \
	gnupg2-scdaemon \
	pass \
	just \
	pre-commit \
	cloc
