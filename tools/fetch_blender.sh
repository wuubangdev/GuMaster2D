#!/usr/bin/env bash
# Download an official, checksum-verified portable Blender; never installs system packages.
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
blender_version=4.5.14
blender_archive="blender-${blender_version}-linux-x64.tar.xz"
blender_sha256=9ba871ff2ecd36526b77432745980b7e6664ecd0c7ca11c48849073dcfe06da3
download_root=https://download.blender.org/release/Blender4.5
tool_root="$project_root/.tools/blender"
binary_root="$tool_root/blender-${blender_version}-linux-x64"

mkdir -p "$tool_root"
if [[ ! -x "$binary_root/blender" ]]; then
    curl --fail --location --retry 3 --user-agent 'Mozilla/5.0' \
        "$download_root/blender-${blender_version}.sha256" \
        --output "$tool_root/blender-${blender_version}.sha256"
    python3 - "$tool_root/blender-${blender_version}.sha256" "$blender_archive" "$blender_sha256" <<'PY'
import pathlib
import sys
checksums = dict(line.split(maxsplit=1)[::-1] for line in pathlib.Path(sys.argv[1]).read_text().splitlines() if line.strip())
if checksums.get(sys.argv[2]) != sys.argv[3]:
    raise SystemExit('Official checksum differs from the pinned checksum; no archive will be executed.')
PY

    if [[ ! -f "$tool_root/$blender_archive" ]]; then
        curl --fail --location --retry 3 --user-agent 'Mozilla/5.0' \
            "$download_root/$blender_archive" --output "$tool_root/$blender_archive.partial"
        mv "$tool_root/$blender_archive.partial" "$tool_root/$blender_archive"
    fi
    printf '%s  %s\n' "$blender_sha256" "$tool_root/$blender_archive" | sha256sum --check --status
    tar --extract --xz --file "$tool_root/$blender_archive" --directory "$tool_root"
fi

# Minimal WSL hosts can lack these X11 loader libraries even in background mode.
# Download authenticated distro packages and unpack them locally; do not install.
if ldd "$binary_root/blender" | rg -q 'lib(SM|ICE).*not found'; then
    mkdir -p "$tool_root/packages" "$tool_root/shared"
    (
        cd "$tool_root/packages"
        apt-get download libsm6 libice6
    )
    for package in "$tool_root/packages/"*.deb; do
        dpkg-deb --extract "$package" "$tool_root/shared"
    done
fi
cat > "$tool_root/blender" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
tool_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export LD_LIBRARY_PATH="$tool_root/shared/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$tool_root/blender-4.5.14-linux-x64/blender" "$@"
WRAPPER
chmod +x "$tool_root/blender"
"$tool_root/blender" --version | head -1
printf '%s\n' "$tool_root/blender"
