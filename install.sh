#!/usr/bin/env bash
# Installs the SDD kit in a project and locks the protected files.
# Usage: install.sh <project-folder> [claude|opencode|codex|both|all] [--profile <profile-folder>]
#                   [--coordinator] [--force] [--no-lock] [--strict]
# A profile is a folder (outside the kit) with profile.md and, optionally, bin/ and skills/.
# --coordinator: the sdd-coordinator agent becomes the project's default agent (Claude Code).
# Targets: both = Claude Code + OpenCode (default); all = the three of them.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$KIT_DIR/lib.sh"

usage() {
  echo "Usage: $0 <project-folder> [claude|opencode|codex|both|all] [--profile <profile-folder>] [--coordinator] [--force] [--no-lock] [--strict]" >&2
  exit 1
}

DEST=""; TARGET="both"; FORCE=0; LOCK=1; STRICT=""; PROFILE=""; COORDINATOR=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    claude|opencode|codex|both|all) TARGET="$1" ;;
    --profile) [[ $# -ge 2 ]] || usage; PROFILE="$2"; shift ;;
    --force) FORCE=1 ;;
    --no-lock) LOCK=0 ;;
    --strict) STRICT="--strict" ;;
    --coordinator) COORDINATOR=1 ;;
    -*) usage ;;
    *) [[ -z "$DEST" ]] && DEST="$1" || usage ;;
  esac
  shift
done
[[ -z "$DEST" ]] && usage
WANT_CLAUDE=0; WANT_OPENCODE=0; WANT_CODEX=0
case "$TARGET" in
  claude) WANT_CLAUDE=1 ;; opencode) WANT_OPENCODE=1 ;; codex) WANT_CODEX=1 ;;
  both) WANT_CLAUDE=1; WANT_OPENCODE=1 ;; all) WANT_CLAUDE=1; WANT_OPENCODE=1; WANT_CODEX=1 ;;
esac
PROFILE_DIR=""
if [[ -n "$PROFILE" ]]; then
  PROFILE_DIR="$(cd "$PROFILE" 2>/dev/null && pwd)" || { echo "Profile not found: $PROFILE" >&2; exit 1; }
  [[ -f "$PROFILE_DIR/profile.md" ]] || { echo "The profile has no profile.md: $PROFILE_DIR" >&2; exit 1; }
fi

PARENT="$(cd "$(dirname "$DEST")" 2>/dev/null && pwd)" || {
  echo "The parent folder of $DEST does not exist" >&2; exit 1; }
DEST="$PARENT/$(basename "$DEST")"
if [[ "$DEST" == "$KIT_DIR" || "$DEST" == "$KIT_DIR"/* ]]; then
  echo "Do not install the kit inside itself." >&2; exit 1
fi
mkdir -p "$DEST"
if is_locked "$DEST"; then
  echo "The project is locked. First run: $KIT_DIR/unlock.sh $DEST" >&2; exit 1
fi

copied=0; skipped=0; merge=()
copy() { # copy <source> <destination> [merge]
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    echo "  skipped (already exists): ${dst#"$DEST"/}"; skipped=$((skipped + 1))
    # (with "if": a false "[[ … ]] && …" would return 1 and set -e would stop the script silently)
    if [[ "${3:-}" == merge ]]; then merge+=("${src#"$KIT_DIR"/} → ${dst#"$DEST"/}"); fi
  else
    cp "$src" "$dst"; echo "  copied: ${dst#"$DEST"/}"; copied=$((copied + 1))
  fi
}

install_commands() { # install_commands <commands-folder>
  for f in "$KIT_DIR"/commands/*.md; do copy "$f" "$DEST/$1/$(basename "$f")"; done
}

echo "Installing the SDD kit in $DEST ($TARGET)"

echo "Templates → docs/sdd-templates/"
for f in "$KIT_DIR"/templates/*.md; do copy "$f" "$DEST/docs/sdd-templates/$(basename "$f")"; done
mkdir -p "$DEST/docs/proposals"

if [[ -n "$PROFILE_DIR" ]]; then
  echo "Profile $(basename "$PROFILE_DIR") → docs/sdd-templates/profile.md and bin/"
  copy "$PROFILE_DIR/profile.md" "$DEST/docs/sdd-templates/profile.md"
  if [[ -d "$PROFILE_DIR/bin" ]]; then
    for f in "$PROFILE_DIR/bin"/*; do
      copy "$f" "$DEST/bin/$(basename "$f")"
      chmod +x "$DEST/bin/$(basename "$f")"
    done
  fi
fi

install_profile_skills() { # install_profile_skills <destination-skills-folder>
  [[ -n "$PROFILE_DIR" && -d "$PROFILE_DIR/skills" ]] || return 0
  local f
  while IFS= read -r f; do
    copy "$f" "$DEST/$1/${f#"$PROFILE_DIR/skills/"}"
  done < <(find "$PROFILE_DIR/skills" -type f)
}

if [[ $WANT_CLAUDE -eq 1 ]]; then
  echo "Claude Code → .claude/"
  install_commands ".claude/commands"
  copy "$KIT_DIR/skills/sdd/SKILL.md" "$DEST/.claude/skills/sdd/SKILL.md"
  install_profile_skills ".claude/skills"
  for f in "$KIT_DIR"/agents/claude/*.md; do copy "$f" "$DEST/.claude/agents/$(basename "$f")"; done
  copy "$KIT_DIR/protect/settings.json" "$DEST/.claude/settings.json" merge
  copy "$KIT_DIR/protect/protect.sh" "$DEST/.claude/hooks/protect.sh"
  chmod +x "$DEST/.claude/hooks/protect.sh"
  # Empty .mcp.json: this way it gets locked and the agent cannot create it to give itself MCP servers.
  if [[ ! -e "$DEST/.mcp.json" ]]; then
    printf '{\n  "mcpServers": {}\n}\n' > "$DEST/.mcp.json"; echo "  created: .mcp.json (empty)"
  fi
  # --coordinator: the coordinator is the default agent when Claude Code opens the project.
  if [[ $COORDINATOR -eq 1 ]]; then
    if command -v jq >/dev/null 2>&1; then
      tmp="$(mktemp)"
      jq '.agent = "sdd-coordinator"' "$DEST/.claude/settings.json" > "$tmp" && mv "$tmp" "$DEST/.claude/settings.json"
      echo "  .claude/settings.json: default agent = sdd-coordinator"
    else
      echo "  WARNING: no jq; add \"agent\": \"sdd-coordinator\" to .claude/settings.json by hand"
    fi
  fi
  # Commands the profile keeps for the container: the hook blocks them.
  if [[ -n "$PROFILE_DIR" && -f "$PROFILE_DIR/deny-commands" ]]; then
    copy "$PROFILE_DIR/deny-commands" "$DEST/.claude/sdd-deny-commands"
  fi
fi

if [[ $WANT_OPENCODE -eq 1 ]]; then
  echo "OpenCode → .opencode/, .agents/ and opencode.json"
  install_commands ".opencode/commands"
  copy "$KIT_DIR/skills/sdd/SKILL.md" "$DEST/.agents/skills/sdd/SKILL.md"
  install_profile_skills ".agents/skills"
  # OpenCode agents: the description and the instructions come from the Claude agent (a single
  # source); the .yml only adds what is specific to OpenCode (mode and permissions).
  for y in "$KIT_DIR"/agents/opencode/*.yml; do
    name="$(basename "$y" .yml)"; src="$KIT_DIR/agents/claude/$name.md"; tmp="$(mktemp)"
    { echo "---"; grep -m1 '^description:' "$src"; cat "$y"; echo "---"
      awk 'n >= 2 { print } /^---$/ { n++ }' "$src"; } > "$tmp"
    copy "$tmp" "$DEST/.opencode/agents/$name.md"; rm -f "$tmp"
  done
  copy "$KIT_DIR/protect/opencode.json" "$DEST/opencode.json" merge
  # Commands the profile keeps for the container: deny rules in opencode.json (there is no hook).
  if [[ -n "$PROFILE_DIR" && -f "$PROFILE_DIR/deny-commands" ]]; then
    if command -v jq >/dev/null 2>&1; then
      DENY_LIST="$(grep -v '^[[:space:]]*#' "$PROFILE_DIR/deny-commands" | tr -d ' \t\r' | grep . || true)"
      TMP_JSON="$(mktemp)"
      jq --arg l "$DENY_LIST" '($l | split("\n") | map(select(length > 0))) as $c
          | reduce $c[] as $x (.; .permission.bash[$x] = "deny" | .permission.bash[$x + " *"] = "deny")' \
        "$DEST/opencode.json" > "$TMP_JSON" && mv "$TMP_JSON" "$DEST/opencode.json"
      echo "  opencode.json: deny for the commands in deny-commands"
    else
      echo "  WARNING: no jq; add the commands in $PROFILE_DIR/deny-commands to opencode.json by hand"
    fi
  fi
fi

if [[ $WANT_CODEX -eq 1 ]]; then
  echo "Codex → .agents/skills/ and .codex/"
  copy "$KIT_DIR/skills/sdd/SKILL.md" "$DEST/.agents/skills/sdd/SKILL.md"
  install_profile_skills ".agents/skills"

  # Codex has no project commands: each /sdd-* is installed as an explicitly invoked skill
  # ($sdd-spec …), with the same text as the command.
  for src in "$KIT_DIR"/commands/sdd-*.md; do
    name="$(basename "$src" .md)"
    desc="$(grep -m1 '^description:' "$src" | sed 's/^description: *//')"
    hint="$(grep -m1 '^argument-hint:' "$src" | sed 's/^argument-hint: *//' || true)"
    a1="<first argument>"; a2="<second argument>"
    if [[ "$hint" =~ ^[[:space:]]*(<[^>]*>|\[[^]]*\])(.*)$ ]]; then
      a1="${BASH_REMATCH[1]}"
      [[ "${BASH_REMATCH[2]}" =~ ^[[:space:]]*(<[^>]*>|\[[^]]*\]) ]] && a2="${BASH_REMATCH[1]}"
    fi
    tmp="$(mktemp)"
    {
      echo "---"
      echo "name: $name"
      printf "description: '%s'\n" "Only when the user invokes it explicitly (\$$name). ${desc//\'/\'\'}"
      echo "---"
      echo "<!-- Generated by the SDD kit's install.sh from commands/$name.md -->"
      echo "Usage: \`\$$name $hint\`. The arguments are the text the user types after the skill"
      echo "name: $a1 is the first one, $a2 the second one and <arguments> everything that follows."
      echo
      awk 'n >= 2 { print } /^---$/ { n++ }' "$src" \
        | sed -e "s#\\\$ARGUMENTS#<arguments>#g" -e "s#\\\$1#$a1#g" -e "s#\\\$2#$a2#g" \
        | sed -e 's#`/sdd-#`$sdd-#g' -e 's#\([[:space:](]\)/sdd-#\1$sdd-#g'
    } > "$tmp"
    copy "$tmp" "$DEST/.agents/skills/$name/SKILL.md"; rm -f "$tmp"
    tmp="$(mktemp)"; printf 'policy:\n  allow_implicit_invocation: false\n' > "$tmp"
    copy "$tmp" "$DEST/.agents/skills/$name/agents/openai.yaml"; rm -f "$tmp"
  done

  # Hook: the same protect.sh. Codex runs it from its working folder, so the project's
  # .codex/hooks folder is searched upwards.
  copy "$KIT_DIR/protect/protect.sh" "$DEST/.codex/hooks/protect.sh"
  chmod +x "$DEST/.codex/hooks/protect.sh"
  HOOK_CMD='sh -c '\''d="$PWD"; while [ "$d" != / ] && [ ! -x "$d/.codex/hooks/protect.sh" ]; do d=$(dirname "$d"); done; exec "$d/.codex/hooks/protect.sh"'\'''
  tmp="$(mktemp)"
  jq -n --arg c "$HOOK_CMD" '{hooks: {PreToolUse: [{matcher: ".*", hooks: [{type: "command", command: $c, statusMessage: "SDD: checking protections"}]}]}}' > "$tmp"
  copy "$tmp" "$DEST/.codex/hooks.json"; rm -f "$tmp"

  # Codex sandbox: writes only inside the project, and no network.
  tmp="$(mktemp)"
  cat > "$tmp" <<'EOF'
# SDD kit: Codex sandbox for this project. Codex only loads .codex/ if you trust the
# project. The scripts in bin/ (Docker) run outside the sandbox, as set in .codex/rules/.
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = false
EOF
  copy "$tmp" "$DEST/.codex/config.toml"; rm -f "$tmp"

  # Codex rules for commands outside the sandbox (generated by the kit; the hook still applies).
  tmp="$(mktemp)"
  {
    echo "# Generated by the SDD kit's install.sh. Codex rules (execpolicy, Starlark)."
    echo "# The scripts in bin/ isolate on their own (a container with no network that only sees"
    echo "# app/) and need Docker, which the Codex sandbox does not allow: they run outside it."
    for f in "$DEST"/bin/*.sh; do
      [[ -e "$f" ]] || continue; b="bin/$(basename "$f")"
      echo "prefix_rule(pattern = [[\"$b\", \"./$b\"]], decision = \"allow\","
      echo "            justification = \"Protected SDD kit script\")"
      echo "prefix_rule(pattern = [[\"$b\", \"./$b\"], \"--net\"], decision = \"prompt\","
      echo "            justification = \"--net gives the container network access\")"
    done
    echo "prefix_rule(pattern = [\"git\", [\"commit\", \"push\", \"add\", \"rm\", \"mv\", \"reset\", \"restore\", \"checkout\","
    echo "                              \"switch\", \"stash\", \"rebase\", \"merge\", \"cherry-pick\", \"revert\","
    echo "                              \"tag\", \"branch\", \"clean\", \"am\", \"apply\", \"pull\", \"fetch\"]],"
    echo "            decision = \"forbidden\", justification = \"git is read-only: the user makes the commits\")"
    echo "# Deleting: to the Trash. trash writes to ~/.Trash (outside the sandbox) and can be undone."
    echo "prefix_rule(pattern = [\"trash\"], decision = \"allow\", justification = \"Moves to the Trash\")"
    for c in rm unlink shred; do
      echo "prefix_rule(pattern = [\"$c\"], decision = \"forbidden\", justification = \"To delete, use trash (Trash)\")"
    done
    for c in gh docker podman nerdctl chflags chmod chown xattr sudo doas; do
      echo "prefix_rule(pattern = [\"$c\"], decision = \"forbidden\", justification = \"Not allowed by the SDD kit\")"
    done
    for c in claude opencode codex; do
      echo "prefix_rule(pattern = [\"$c\", \"mcp\"], decision = \"forbidden\", justification = \"MCP servers are set up by the user\")"
    done
    if [[ -n "$PROFILE_DIR" && -f "$PROFILE_DIR/deny-commands" ]]; then
      grep -v '^[[:space:]]*#' "$PROFILE_DIR/deny-commands" | tr -d ' \t\r' | grep . | while IFS= read -r c; do
        echo "prefix_rule(pattern = [\"$c\"], decision = \"forbidden\", justification = \"Only inside the container (bin/)\")"
      done
    fi
  } > "$tmp"
  copy "$tmp" "$DEST/.codex/rules/sdd.rules"; rm -f "$tmp"
  if [[ -n "$PROFILE_DIR" && -f "$PROFILE_DIR/deny-commands" ]]; then
    copy "$PROFILE_DIR/deny-commands" "$DEST/.codex/sdd-deny-commands"
  fi
fi

echo "Done: $copied copied, $skipped skipped."
if [[ ${#merge[@]} -gt 0 ]]; then
  echo "ATTENTION: merge the protection settings by hand (they were not overwritten):"
  for m in "${merge[@]}"; do echo "  $m"; done
fi

if [[ $LOCK -eq 1 ]]; then
  "$KIT_DIR/lock.sh" "$DEST" $STRICT
else
  echo "Not locked (--no-lock). Lock with: $KIT_DIR/lock.sh $DEST"
fi
echo "Next step: open a new agent session in $DEST and run /sdd-constitution"
if [[ $WANT_CODEX -eq 1 ]]; then
  echo "In Codex: open it in $DEST, mark the project as trusted, review and approve the hook"
  echo "with /hooks, and use the skills: \$sdd-constitution, \$sdd-spec 001-name idea…"
fi
