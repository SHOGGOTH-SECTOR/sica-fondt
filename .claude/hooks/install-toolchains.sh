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
ALR_SHA256="2e2b8de009b793ad2aed10096e162649bbcc5b0711e3c21785ebe8a1261c5d64"
if command -v alr >/dev/null 2>&1; then
  log "alr present; verifying integrity."
  echo "$ALR_SHA256  $(command -v alr)" | sha256sum -c - || die "Installed alr sha256 mismatch — binary may be corrupt."
else
  log "Installing Alire (alr) 2.1.1 ..."
  curl -sSL -o /tmp/alr.zip https://github.com/alire-project/alire/releases/download/v2.1.1/alr-2.1.1-bin-x86_64-linux.zip || die "Alire download failed."
  ( cd /tmp && unzip -o -q alr.zip ) || die "Alire unzip failed."
  echo "$ALR_SHA256  /tmp/bin/alr" | sha256sum -c - || die "Downloaded alr sha256 mismatch."
  sudo cp /tmp/bin/alr /usr/local/bin/alr && chmod +x /usr/local/bin/alr || die "Alire copy failed."
  log "alr installed to /usr/local/bin/alr"
fi

# ---------------------------------------------------------------------------
# Fortran 2018 (gfortran) + OpenBLAS  (economy organ: M3d, M3e, M3g)
# ---------------------------------------------------------------------------
if command -v gfortran >/dev/null 2>&1; then
  log "gfortran already present; skipping."
else
  log "Installing gfortran libopenblas-dev via apt-get ..."
  sudo apt-get install -y gfortran libopenblas-dev || die "apt-get install of gfortran/libopenblas-dev failed."
fi

# ---------------------------------------------------------------------------
# fpm — Fortran Package Manager  (economy organ: M3d, M3e, M3g)
# ---------------------------------------------------------------------------
if command -v fpm >/dev/null 2>&1 && fpm --version >/dev/null 2>&1; then
  log "fpm already present; skipping."
else
  log "Installing fpm via pip ..."
  pip install --quiet fpm==0.12.0 || die "pip install fpm failed."
  log "fpm $(fpm --version 2>&1 | head -1)"
fi

# ---------------------------------------------------------------------------
# R + vital CRAN packages  (economy organ: M3a statistical sims)
# Vital: HiddenMarkov (HMM regime detection), rugarch (GARCH volatility),
# rmgarch (DCC-GARCH correlation). Everything else in M3a is hand-rolled.
# ---------------------------------------------------------------------------
if command -v Rscript >/dev/null 2>&1 \
  && Rscript -e 'library(HiddenMarkov); library(rugarch); library(rmgarch)' >/dev/null 2>&1; then
  log "R + HiddenMarkov/rugarch/rmgarch already present; skipping."
else
  log "Installing r-base-core via apt-get ..."
  sudo apt-get install -y r-base-core || die "apt-get install of r-base-core failed."
  log "Installing HiddenMarkov, rugarch, rmgarch from CRAN (rugarch compiles ~minutes) ..."
  Rscript -e 'install.packages(c("HiddenMarkov","rugarch","rmgarch"), repos="https://cloud.r-project.org", quiet=TRUE)' \
    || die "CRAN install of HiddenMarkov/rugarch/rmgarch failed."
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
# ECLiPSe Prolog 7.2_13  (economy organ: M3b, M3f)
# Bundles: basic (includes ic), if_osiclpcbc (COIN-OR backend for eplex LP/MIP)
# ---------------------------------------------------------------------------
ECL_MIRROR="https://www.mirrorservice.org/sites/eclipseclp.org/Distribution/CurrentRelease"
ECL_PLATFORM="7.2_13%20x86_64_linux%20Intel-64bit-Linux"
ECL_BASIC_SHA256="df12d7ab694331f54cd87e5861ceec2ddd41028d1cccf6496ec56ea6755600a3"
ECL_OSICLPCBC_SHA256="a90d34a19606c916a684b8a8927dda441b743a11d07dbfe0de007c38f9844df6"
if [ -x /opt/eclipseclp/lib/x86_64_linux/eclipse.exe ]; then
  log "ECLiPSe Prolog present; verifying."
  [ -f /opt/eclipseclp/lib/x86_64_linux/ic.so ] || die "ECLiPSe ic library missing."
  [ -f /opt/eclipseclp/lib/x86_64_linux/seosiclpcbc.so ] || die "ECLiPSe eplex COIN-OR backend missing."
else
  log "Installing ECLiPSe Prolog 7.2_13 ..."
  sudo apt-get install -y coinor-libcbc3.1 || die "COIN-OR CBC system library install failed."
  sudo mkdir -p /opt/eclipseclp || die "Could not create /opt/eclipseclp."
  curl -sSL -o /tmp/eclipse_basic.tgz "$ECL_MIRROR/$ECL_PLATFORM/eclipse_basic.tgz" \
    || die "ECLiPSe basic download failed."
  echo "$ECL_BASIC_SHA256  /tmp/eclipse_basic.tgz" | sha256sum -c - \
    || die "ECLiPSe basic sha256 mismatch."
  sudo tar -xzf /tmp/eclipse_basic.tgz -C /opt/eclipseclp \
    || die "ECLiPSe basic extraction failed."
  curl -sSL -o /tmp/if_osiclpcbc.tgz "$ECL_MIRROR/$ECL_PLATFORM/if_osiclpcbc.tgz" \
    || die "ECLiPSe COIN-OR download failed."
  echo "$ECL_OSICLPCBC_SHA256  /tmp/if_osiclpcbc.tgz" | sha256sum -c - \
    || die "ECLiPSe COIN-OR sha256 mismatch."
  sudo tar -xzf /tmp/if_osiclpcbc.tgz -C /opt/eclipseclp \
    || die "ECLiPSe COIN-OR extraction failed."
  log "ECLiPSe 7.2_13 installed to /opt/eclipseclp (basic + ic + eplex/COIN-OR)"
fi

# ---------------------------------------------------------------------------
# Solidity / Foundry  (economy organ: M3c — hosted separately)
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
EXTRA_PATHS='/root/.local/share/ponyup/bin:/opt/eclipseclp/lib/x86_64_linux'
FOUNDRY_PATH="$HOME/.foundry/bin"
FULL_PATH_LINE="export PATH=$EXTRA_PATHS:$FOUNDRY_PATH:\$PATH"
ECLIPSEDIR_LINE="export ECLIPSEDIR=/opt/eclipseclp"
if [ -f "$HOME/.bashrc" ] && grep -qF "ECLIPSEDIR" "$HOME/.bashrc"; then
  log "Toolchain PATH/env lines already in ~/.bashrc; skipping."
else
  log "Appending toolchain PATH/env lines to ~/.bashrc"
  { echo "$FULL_PATH_LINE"; echo "$ECLIPSEDIR_LINE"; } >> "$HOME/.bashrc" \
    || die "Could not append to ~/.bashrc."
fi

log "Done."
