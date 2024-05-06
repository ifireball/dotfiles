#!/bin/bash
set -eu

#region logging setup
if [ "${MISE_DEBUG-}" = "true" ] || [ "${MISE_DEBUG-}" = "1" ]; then
	debug() {
		echo "$@" >&2
	}
else
	debug() {
		:
	}
fi

if [ "${MISE_QUIET-}" = "1" ] || [ "${MISE_QUIET-}" = "true" ]; then
	info() {
		:
	}
else
	info() {
		echo "$@" >&2
	}
fi

error() {
	echo "$@" >&2
	exit 1
}
#endregion

#region environment setup
get_os() {
	os="$(uname -s)"
	if [ "$os" = Darwin ]; then
		echo "macos"
	elif [ "$os" = Linux ]; then
		echo "linux"
	else
		error "unsupported OS: $os"
	fi
}

get_arch() {
	musl=""
	if type ldd >/dev/null 2>/dev/null; then
		libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
		if [ -n "$libc" ]; then
			musl="-musl"
		fi
	fi
	arch="$(uname -m)"
	if [ "$arch" = x86_64 ]; then
		echo "x64$musl"
	elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
		echo "arm64$musl"
	elif [ "$arch" = armv6l ]; then
		echo "armv6$musl"
	elif [ "$arch" = armv7l ]; then
		echo "armv7$musl"
	else
		error "unsupported architecture: $arch"
	fi
}

shasum_bin() {
	if command -v shasum >/dev/null 2>&1; then
		echo "shasum"
	elif command -v sha256sum >/dev/null 2>&1; then
		echo "sha256sum"
	else
		error "mise install requires shasum or sha256sum but neither is installed. Aborting."
	fi
}

get_checksum() {
	os="$(get_os)"
	arch="$(get_arch)"

	checksum_linux_x86_64="260c5866a0690f855b40846768a222db76d7c24ac3a8a16c325993792ee657c6  ./mise-v2024.5.2-linux-x64.tar.gz"
	checksum_linux_x86_64_musl="eb9ad3a2eb22a065082b102d5111f28afbf5aefb19cfc71e884bed8f4eee120b  ./mise-v2024.5.2-linux-x64-musl.tar.gz"
	checksum_linux_arm64="2d9aeea9f86b34f87259e342834249d02deaac4ed0be5a90b5a79cc6e0903d96  ./mise-v2024.5.2-linux-arm64.tar.gz"
	checksum_linux_arm64_musl="432b19fad28b401f0fb0c8942bda9cbf3f0534863563cc60cd40a7417aa68ae2  ./mise-v2024.5.2-linux-arm64-musl.tar.gz"
	checksum_linux_armv6="842dc685cfb75fea48eedfb44ff2817d17ac1fe84227cd174cfa028885f7c9e3  ./mise-v2024.5.2-linux-armv6.tar.gz"
	checksum_linux_armv6_musl="2e0fbf29714dfd9edbcb6bbcfe26e5e7ba1bdf5aede23c2099dbac236a7da7d1  ./mise-v2024.5.2-linux-armv6-musl.tar.gz"
	checksum_linux_armv7="1ad69aae39661043a42ff2d28cdbc955c167a38166608469db0ee9990d0ee05c  ./mise-v2024.5.2-linux-armv7.tar.gz"
	checksum_linux_armv7_musl="e870a661b6ad32e9e8c343bc9cfb0491a0771f32d55ef67471e61e6535c0fe3f  ./mise-v2024.5.2-linux-armv7-musl.tar.gz"
	checksum_macos_x86_64="8d11ead35112ce185fb79b746b41ad649f9e61ff72dcff6fd5d0c9c080644910  ./mise-v2024.5.2-macos-x64.tar.gz"
	checksum_macos_arm64="b9e1b064099cb3022199a626bac2cb50bac85e79ccea967e3f693c3bf18e590c  ./mise-v2024.5.2-macos-arm64.tar.gz"

	if [ "$os" = "linux" ]; then
		if [ "$arch" = "x64" ]; then
			echo "$checksum_linux_x86_64"
		elif [ "$arch" = "x64-musl" ]; then
			echo "$checksum_linux_x86_64_musl"
		elif [ "$arch" = "arm64" ]; then
			echo "$checksum_linux_arm64"
		elif [ "$arch" = "arm64-musl" ]; then
			echo "$checksum_linux_arm64_musl"
		elif [ "$arch" = "armv6" ]; then
			echo "$checksum_linux_armv6"
		elif [ "$arch" = "armv6-musl" ]; then
			echo "$checksum_linux_armv6_musl"
		elif [ "$arch" = "armv7" ]; then
			echo "$checksum_linux_armv7"
		elif [ "$arch" = "armv7-musl" ]; then
			echo "$checksum_linux_armv7_musl"
		else
			warn "no checksum for $os-$arch"
		fi
	elif [ "$os" = "macos" ]; then
		if [ "$arch" = "x64" ]; then
			echo "$checksum_macos_x86_64"
		elif [ "$arch" = "arm64" ]; then
			echo "$checksum_macos_arm64"
		else
			warn "no checksum for $os-$arch"
		fi
	else
		warn "no checksum for $os-$arch"
	fi
}

#endregion

download_file() {
	url="$1"
	filename="$(basename "$url")"
	cache_dir="$(mktemp -d)"
	file="$cache_dir/$filename"

	info "mise: installing mise..."

	if command -v curl >/dev/null 2>&1; then
		debug ">" curl -#fLo "$file" "$url"
		curl -#fLo "$file" "$url"
	else
		if command -v wget >/dev/null 2>&1; then
			debug ">" wget -qO "$file" "$url"
			stderr=$(mktemp)
			wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
		else
			error "mise standalone install requires curl or wget but neither is installed. Aborting."
		fi
	fi

	echo "$file"
}

install_mise() {
	# download the tarball
	version="v2024.5.2"
	os="$(get_os)"
	arch="$(get_arch)"
	install_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
	install_dir="$(dirname "$install_path")"
	tarball_url="https://github.com/jdx/mise/releases/download/${version}/mise-${version}-${os}-${arch}.tar.gz"

	cache_file=$(download_file "$tarball_url")
	debug "mise-setup: tarball=$cache_file"

	debug "validating checksum"
	cd "$(dirname "$cache_file")" && get_checksum | "$(shasum_bin)" -c >/dev/null

	# extract tarball
	mkdir -p "$install_dir"
	rm -rf "$install_path"
	cd "$(mktemp -d)"
	tar -xzf "$cache_file"
	mv mise/bin/mise "$install_path"
	info "mise: installed successfully to $install_path"
}

type -t mise >> /dev/null || install_mise
