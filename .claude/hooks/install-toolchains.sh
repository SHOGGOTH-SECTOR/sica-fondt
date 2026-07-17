#!/bin/bash
# SessionStart hook — install the polyglot build toolchains for this repo.
#
# Claude Code on the web runs in an ephemeral container: anything installed
# outside the cached project tree vanishes on restart. This hook reinstalls the
# toolchains the project depends on at the start of every session:
#   * GNAT + gprbuild + GnuCOBOL   (apt: gnat gprbuild gnucobol)
#   * Pony (ponyc) via ponyup
#   * Alire (alr) 2.1.1            (prebuilt release zip)
#
# Design rules:
#   * IDEMPOTENT — each tool is skipped if it is already on PATH (command -v).
#   * NON-FATAL — a failed download/install must NOT break the session. We never
#     run `set -e`; every step is guarded and the script always exits 0.
#   * Warnings (not errors) are logged so failures are visible in the session log.

log()  { echo "[install-toolchains] $*"; }
warn() { echo "[install-toolchains] WARNING: $*" >&2; }

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# GNAT + gprbuild + GnuCOBOL (apt)
# ---------------------------------------------------------------------------
if command -v gnatmake >/dev/null 2>&1 && command -v cobc >/dev/null 2>&1; then
  log "GNAT/gprbuild/GnuCOBOL already present; skipping apt install."
else
  log "Installing gnat gprbuild gnucobol via apt-get ..."
  if ! sudo apt-get install -y gnat gprbuild gnucobol; then
    warn "apt-get install of gnat/gprbuild/gnucobol failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Pony (ponyc) via ponyup
# ---------------------------------------------------------------------------
if command -v ponyc >/dev/null 2>&1; then
  log "ponyc already present; skipping ponyup install."
else
  log "Installing ponyc via ponyup ..."
  if sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"; then
    if ! /root/.local/share/ponyup/bin/ponyup update ponyc release; then
      warn "ponyup update ponyc release failed; continuing."
    fi
  else
    warn "ponyup-init.sh download/run failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Alire (alr) 2.1.1
# ---------------------------------------------------------------------------
if command -v alr >/dev/null 2>&1; then
  log "alr already present; skipping Alire install."
else
  log "Installing Alire (alr) 2.1.1 ..."
  if curl -sSL -o /tmp/alr.zip https://github.com/alire-project/alire/releases/download/v2.1.1/alr-2.1.1-bin-x86_64-linux.zip; then
    if ( cd /tmp && unzip -o -q alr.zip && sudo cp bin/alr /usr/local/bin/alr && chmod +x /usr/local/bin/alr ); then
      log "alr installed to /usr/local/bin/alr"
    else
      warn "Alire unzip/copy failed; continuing."
    fi
  else
    warn "Alire download failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Fortran 2018 (gfortran) + OpenBLAS  (economy organ: M3d, M3e)
# ---------------------------------------------------------------------------
if command -v gfortran >/dev/null 2>&1; then
  log "gfortran already present; skipping."
else
  log "Installing gfortran libopenblas-dev via apt-get ..."
  if ! sudo apt-get install -y gfortran libopenblas-dev; then
    warn "apt-get install of gfortran/libopenblas-dev failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# fpm — Fortran Package Manager  (economy organ: M3d, M3e)
# ---------------------------------------------------------------------------
if command -v fpm >/dev/null 2>&1; then
  log "fpm already present; skipping."
else
  log "Installing fpm ..."
  FPM_URL="https://github.com/fortran-lang/fpm/releases/download/v0.10.1/fpm-0.10.1-linux-x86_64"
  if curl -sSL -o /tmp/fpm "$FPM_URL"; then
    sudo cp /tmp/fpm /usr/local/bin/fpm && sudo chmod +x /usr/local/bin/fpm
    log "fpm installed to /usr/local/bin/fpm"
  else
    warn "fpm download failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Tcl  (economy organ: M3 sim hub)
# ---------------------------------------------------------------------------
if command -v tclsh >/dev/null 2>&1; then
  log "tclsh already present; skipping."
else
  log "Installing tcl via apt-get ..."
  if ! sudo apt-get install -y tcl; then
    warn "apt-get install of tcl failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# ECLiPSe Prolog  (economy organ: M3b, M3f)
# ---------------------------------------------------------------------------
if command -v eclipse >/dev/null 2>&1 || [ -x /opt/eclipseclp/bin/x86_64_linux/eclipse ]; then
  log "ECLiPSe Prolog already present; skipping."
else
  log "Installing ECLiPSe Prolog ..."
  ECLIPSE_URL="https://eclipseclp.org/Distribution/Current/7.1_13/x86_64_linux/eclipse_basic.tgz"
  if curl -sSL -o /tmp/eclipse_basic.tgz "$ECLIPSE_URL"; then
    if sudo mkdir -p /opt/eclipseclp && sudo tar -xzf /tmp/eclipse_basic.tgz -C /opt/eclipseclp; then
      log "ECLiPSe installed to /opt/eclipseclp"
    else
      warn "ECLiPSe extraction failed; continuing."
    fi
  else
    warn "ECLiPSe download failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Zig  (economy organ: M3g)
# ---------------------------------------------------------------------------
if command -v zig >/dev/null 2>&1; then
  log "zig already present; skipping."
else
  log "Installing Zig ..."
  ZIG_URL="https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz"
  if curl -sSL -o /tmp/zig.tar.xz "$ZIG_URL"; then
    if sudo tar -xJf /tmp/zig.tar.xz -C /opt && sudo ln -sf /opt/zig-linux-x86_64-0.13.0/zig /usr/local/bin/zig; then
      log "zig installed to /usr/local/bin/zig"
    else
      warn "Zig extraction/linking failed; continuing."
    fi
  else
    warn "Zig download failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Solidity / Foundry  (economy organ: M3c)
# ---------------------------------------------------------------------------
if command -v forge >/dev/null 2>&1; then
  log "forge (Foundry) already present; skipping."
else
  log "Installing Foundry (forge, anvil) ..."
  if curl -sSL https://foundry.paradigm.xyz | bash; then
    if "$HOME/.foundry/bin/foundryup"; then
      log "Foundry installed"
    else
      warn "foundryup failed; continuing."
    fi
  else
    warn "Foundry install script failed; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# Ensure ponyc is on PATH for future shells.
# ---------------------------------------------------------------------------
EXTRA_PATHS='/root/.local/share/ponyup/bin:/opt/eclipseclp/bin/x86_64_linux'
FOUNDRY_PATH="$HOME/.foundry/bin"
FULL_PATH_LINE="export PATH=$EXTRA_PATHS:$FOUNDRY_PATH:\$PATH"
if [ -f "$HOME/.bashrc" ] && grep -qF "eclipseclp" "$HOME/.bashrc"; then
  log "Economy-organ PATH lines already in ~/.bashrc; skipping."
else
  log "Appending toolchain PATH lines to ~/.bashrc"
  echo "$FULL_PATH_LINE" >> "$HOME/.bashrc" || warn "Could not append to ~/.bashrc; continuing."
fi

log "Done."
# Never fail the session, regardless of what happened above.
exit 0
