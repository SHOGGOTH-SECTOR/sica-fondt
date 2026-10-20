#!/bin/bash
# SessionStart non-apt toolchains for sica-fondt.
#
# ECLiPSe CLP is required by M3b/M3f and is not distributed as a reliable
# Ubuntu apt package. Install the official x86_64 Linux binary distribution
# idempotently. Foundry remains separately hosted by design (M3c).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ "${SICA_INSTALL_TOOLCHAINS:-}" != "true" ]; then
  exit 0
fi

ECLIPSE_VERSION="7.2_13"
ECLIPSE_ARCH="x86_64_linux"
ECLIPSE_ROOT="/opt/eclipse-clp-${ECLIPSE_VERSION}"
ECLIPSE_BASE="https://eclipseclp.org/Distribution/Builds/${ECLIPSE_VERSION}/${ECLIPSE_ARCH}"

if ! command -v eclipse >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  curl --fail --location --silent --show-error     "${ECLIPSE_BASE}/eclipse_basic.tgz"     --output "${tmp}/eclipse_basic.tgz"

  sudo mkdir -p "${ECLIPSE_ROOT}"
  sudo tar -xzf "${tmp}/eclipse_basic.tgz" -C "${ECLIPSE_ROOT}"

  sudo tee /usr/local/bin/eclipse >/dev/null <<EOF
#!/bin/sh
ECLIPSEDIR="${ECLIPSE_ROOT}"
export ECLIPSEDIR
export LD_LIBRARY_PATH="${ECLIPSE_ROOT}/lib/${ECLIPSE_ARCH}:\${LD_LIBRARY_PATH:-}"
exec "${ECLIPSE_ROOT}/lib/${ECLIPSE_ARCH}/eclipse.exe" -D "${ECLIPSE_ROOT}" "\$@"
EOF
  sudo chmod 0755 /usr/local/bin/eclipse
fi

# Fail loudly if the installed runtime cannot execute a noninteractive goal.
eclipse -e 'writeln("ECLIPSE_TOOLCHAIN_READY")'
