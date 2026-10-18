# Shared functions for the SDD kit scripts (loaded with "source").

# Protected paths, relative to the project root.
PROTECTED=(.claude .opencode .agents .codex opencode.json .mcp.json bin docs/constitution.md AGENTS.md CLAUDE.md)
LOCK_MARKER=".claude/sdd-lock"

project_dir() { # project_dir <path>  → absolute path of an existing project
  [[ -n "${1:-}" && -d "$1" ]] || { echo "Project not found: ${1:-<empty>}" >&2; exit 1; }
  (cd -P "$1" && pwd)
}

existing_protected() { # existing_protected <project>
  local p
  for p in "${PROTECTED[@]}"; do [[ -e "$1/$p" ]] && echo "$1/$p"; done
  return 0
}

is_locked() { # is_locked <project>  → 0 if any protected file is locked
  local targets=()
  while IFS= read -r t; do targets+=("$t"); done < <(existing_protected "$1")
  [[ ${#targets[@]} -eq 0 ]] && return 1
  [[ -n "$(find "${targets[@]}" \( -flags +uchg -o -user root \) -print -quit 2>/dev/null)" ]]
}
