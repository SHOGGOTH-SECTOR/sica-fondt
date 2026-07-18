#!/bin/bash
set -euo pipefail

# SessionStart hook — install the polyglot build toolchains for this repo.
#
# Claude Code on the web runs in an ephemeral container: anything installed
# outside the cached project tree vanishes on restart. This hook reinstalls the
# toolchains the project depends on at the start of every session.
#
# Design rules:
#   * IDEMPOTENT — each tool is skipped if it is already on PATH (command -v).
#   * HARD FAIL — if an install fails, the session cannot build. Stop.

log() { echo "[install-toolchains] $*"; }
die() { echo "[install-toolchains] FATAL: $*" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# GNAT + gprbuild + GnuCOBOL (apt)
# ---------------------------------------------------------------------------
if command -v gnatmake >/dev/null 2>&1 && command -v cobc >/dev/null 2>&1; then
  log "GNAT/gprbuild/GnuCOBOL already present; skipping apt install."
else
  log "Installing gnat gprbuild gnucobol via apt-get ..."
  sudo apt-get install -y gnat gprbuild gnucobol || die "apt-get install of gnat/gprbuild/gnucobol failed."
fi

# ---------------------------------------------------------------------------
# Pony (ponyc) via ponyup
# ---------------------------------------------------------------------------
if command -v ponyc >/dev/null 2>&1; then
  log "ponyc already present; skipping ponyup install."
else
  log "Installing ponyc via ponyup ..."
  sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)" || die "ponyup-init.sh failed."
  /root/.local/share/ponyup/bin/ponyup update ponyc release || die "ponyup update ponyc release failed."
fi

# ---------------------------------------------------------------------------
# Alire (alr) 2.1.1
# ---------------------------------------------------------------------------
if command -v alr >/dev/null 2>&1; then
  log "alr already present; skipping Alire install."
else
  log "Installing Alire (alr) 2.1.1 ..."
  curl -sSL -o /tmp/alr.zip https://github.com/alire-project/alire/releases/download/v2.1.1/alr-2.1.1-bin-x86_64-linux.zip || die "Alire download failed."
  ( cd /tmp && unzip -o -q alr.zip && sudo cp bin/alr /usr/local/bin/alr && chmod +x /usr/local/bin/alr ) || die "Alire unzip/copy failed."
  log "alr installed to /usr/local/bin/alr"
fi

# ---------------------------------------------------------------------------
# Fortran 2018 (gfortran) + OpenBLAS  (economy organ: M3d, M3e)
# ---------------------------------------------------------------------------
if command -v gfortran >/dev/null 2>&1; then
  log "gfortran already present; skipping."
else
  log "Installing gfortran libopenblas-dev via apt-get ..."
  sudo apt-get install -y gfortran libopenblas-dev || die "apt-get install of gfortran/libopenblas-dev failed."
fi

# ---------------------------------------------------------------------------
# fpm — Fortran Package Manager  (economy organ: M3d, M3e)
# ---------------------------------------------------------------------------
if command -v fpm >/dev/null 2>&1; then
  log "fpm already present; skipping."
else
  log "Installing fpm ..."
  FPM_URL="https://github.com/fortran-lang/fpm/releases/download/v0.10.1/fpm-0.10.1-linux-x86_64"
  curl -sSL -o /tmp/fpm "$FPM_URL" || die "fpm download failed."
  sudo cp /tmp/fpm /usr/local/bin/fpm && sudo chmod +x /usr/local/bin/fpm || die "fpm install failed."
  log "fpm installed to /usr/local/bin/fpm"
fi

# ---------------------------------------------------------------------------
# Tcl  (economy organ: M3 sim hub)
# ---------------------------------------------------------------------------
if command -v tclsh >/dev/null 2>&1; then
  log "tclsh already present; skipping."
else
  log "Installing tcl via apt-get ..."
  sudo apt-get install -y tcl || die "apt-get install of tcl failed."
fi

# ---------------------------------------------------------------------------
# ECLiPSe Prolog  (economy organ: M3b, M3f)
# ---------------------------------------------------------------------------
if command -v eclipse >/dev/null 2>&1 || [ -x /opt/eclipseclp/bin/x86_64_linux/eclipse ]; then
  log "ECLiPSe Prolog already present; skipping."
else
  log "Installing ECLiPSe Prolog ..."
  ECLIPSE_URL="https://eclipseclp.org/Distribution/Current/7.1_13/x86_64_linux/eclipse_basic.tgz"
  curl -sSL -o /tmp/eclipse_basic.tgz "$ECLIPSE_URL" || die "ECLiPSe download failed."
  sudo mkdir -p /opt/eclipseclp || die "Could not create /opt/eclipseclp."
  sudo tar -xzf /tmp/eclipse_basic.tgz -C /opt/eclipseclp || die "ECLiPSe extraction failed."
  log "ECLiPSe installed to /opt/eclipseclp"
fi

# --------------------------------------------------------------------------- ---------------------------------------------------------------------------
# Solidity / Foundry  (economy organ: M3c)
# ---------------------------------------------------------------------------
# if command -v forge >/dev/null 2>&1; then
#  log "forge (Foundry) already present; skipping."
# else
#  log "Installing Foundry (forge, anvil) ..."
#  curl -sSL https://foundry.paradigm.xyz | bash || die "Foundry install script failed."
#  "$HOME/.foundry/bin/foundryup" || die "foundryup failed."
#  log "Foundry installed"
# fi

# ---------------------------------------------------------------------------
# PATH for tools not in standard locations.
# ---------------------------------------------------------------------------
EXTRA_PATHS='/root/.local/share/ponyup/bin:/opt/eclipseclp/bin/x86_64_linux'
FOUNDRY_PATH="$HOME/.foundry/bin"
FULL_PATH_LINE="export PATH=$EXTRA_PATHS:$FOUNDRY_PATH:\$PATH"
if [ -f "$HOME/.bashrc" ] && grep -qF "eclipseclp" "$HOME/.bashrc"; then
  log "Toolchain PATH lines already in ~/.bashrc; skipping."
else
  log "Appending toolchain PATH lines to ~/.bashrc"
  echo "$FULL_PATH_LINE" >> "$HOME/.bashrc" || die "Could not append to ~/.bashrc."
fi

log "Done."
