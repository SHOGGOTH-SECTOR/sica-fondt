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
# Ensure ponyc is on PATH for future shells.
# ---------------------------------------------------------------------------
PONY_PATH_LINE='export PATH=/root/.local/share/ponyup/bin:$PATH'
if [ -f "$HOME/.bashrc" ] && grep -qF "$PONY_PATH_LINE" "$HOME/.bashrc"; then
  log "ponyup PATH line already in ~/.bashrc; skipping."
else
  log "Appending ponyup PATH line to ~/.bashrc"
  echo "$PONY_PATH_LINE" >> "$HOME/.bashrc" || warn "Could not append to ~/.bashrc; continuing."
fi

log "Done."
# Never fail the session, regardless of what happened above.
exit 0
