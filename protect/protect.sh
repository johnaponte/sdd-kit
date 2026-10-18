#!/usr/bin/env bash
# PreToolUse hook of the SDD kit (Claude Code and Codex): stops the agent from changing the
# method's protected files. exit 0 = allow; exit 2 = block (stderr reaches the agent).
set -uo pipefail

INPUT="$(cat)"
# Claude Code sets CLAUDE_PROJECT_DIR; Codex does not (the root is searched from "cwd", below).
IS_CLAUDE=0; [[ -n "${CLAUDE_PROJECT_DIR:-}" ]] && IS_CLAUDE=1

block() {   # general block (tool or command not allowed)
  echo "SDD: blocked. $1" >&2
  echo "Do not try to get around this block: tell the user." >&2
  exit 2
}

block_protected() {   # block for touching one of the method's protected files
  echo "SDD: blocked. $1" >&2
  echo "The method's files are protected (.claude/, .opencode/, .agents/, .codex/, opencode.json, .mcp.json, bin/," \
       "docs/constitution.md, AGENTS.md, CLAUDE.md). Write your proposal in docs/proposals/ and" \
       "ask the user to promote it. Do not try to get around this block: tell the user." >&2
  exit 2
}

# Block because of the agent's role (sdd-coordinator, sdd-planner, sdd-implementer, sdd-reviewer).
role_block() {
  echo "SDD: blocked. $1" >&2
  echo "This is a limit of this agent's role in the SDD flow. Do not try to get around it:" \
       "hand the work back to the coordinator or tell the user." >&2
  exit 2
}

lower() { tr '[:upper:]' '[:lower:]' <<<"$1"; }

field() { # field tool_name|file_path|command|agent_type|cwd
  if command -v jq >/dev/null 2>&1; then
    case "$1" in
      tool_name)  jq -r '.tool_name // ""' <<<"$INPUT" ;;
      file_path)  jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$INPUT" ;;
      command)    jq -r '.tool_input.command // ""' <<<"$INPUT" ;;
      agent_type) jq -r '.agent_type // ""' <<<"$INPUT" ;;
      cwd)        jq -r '.cwd // ""' <<<"$INPUT" ;;
    esac
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
d = json.loads(sys.argv[2]); t = d.get("tool_input") or {}
v = {"tool_name": d.get("tool_name"),
     "file_path": t.get("file_path") or t.get("notebook_path"),
     "command": t.get("command"),
     "agent_type": d.get("agent_type"),
     "cwd": d.get("cwd")}[sys.argv[1]]
print(v or "")' "$1" "$INPUT"
  else
    return 1
  fi
}

# Real absolute path, even if the file (or its folders) does not exist yet.
resolve() {
  local p="$1" rest="" dir base
  [[ "$p" == /* ]] || p="$REL_BASE/$p"   # Claude: project root; Codex: its cwd
  if [[ -L "$p" ]]; then p="$(readlink -f "$p" 2>/dev/null || echo "$p")"; fi
  dir="$(dirname "$p")"; base="$(basename "$p")"
  while [[ ! -d "$dir" ]]; do rest="/$(basename "$dir")$rest"; dir="$(dirname "$dir")"; done
  [[ "$rest/$base" == *..* ]] && return 1   # ".." inside missing folders: cannot be resolved
  echo "$(cd -P "$dir" && pwd)$rest/$base"
}

is_protected() { # is_protected <path relative to the project>
  case "$(lower "$1")" in
    .claude|.claude/*|.opencode|.opencode/*|.agents|.agents/*|.codex|.codex/*) return 0 ;;
    opencode.json|.mcp.json|bin|bin/*) return 0 ;;
    docs/constitution.md|agents.md|claude.md) return 0 ;;
  esac
  return 1
}

check_edit() {
  local fp="$1" abs root rel=""
  [[ -z "$fp" ]] && return 0
  abs="$(resolve "$fp")" || block "Path cannot be resolved: $fp"
  root="$(cd -P "$PROJECT" && pwd)"
  abs="$(lower "$abs")"; root="$(lower "$root")"
  if [[ "$abs" == "$root"/* ]]; then
    rel="${abs#"$root"/}"
    is_protected "$rel" && block_protected "$fp cannot be edited."
  fi
  check_role_edit "$rel" "$fp"     # empty rel = outside the project
  return 0
}

# What each SDD role may edit (paths relative to the project, lower case).
check_role_edit() { # check_role_edit <rel> <original path>
  case "$AGENT" in
    sdd-coordinator|sdd-reviewer)
      role_block "Agent $AGENT does not edit files ($2)." ;;
    sdd-planner)
      [[ "$1" == specs/* ]] || role_block "sdd-planner only writes inside specs/ ($2)." ;;
    sdd-implementer)
      [[ "$1" == app/* || "$1" =~ ^specs/[^/]+/tasks\.md$ || "$1" == memory.md ]] \
        || role_block "sdd-implementer only edits app/, a spec's tasks.md and MEMORY.md ($2)." ;;
  esac
  return 0
}

READ_ONLY='^(cat|head|tail|less|more|grep|egrep|fgrep|rg|ls|wc|diff|stat|file|find|cd|pwd|echo)$'
TOOL_SCRIPT='^(\./)?bin/[a-z0-9._-]+\.sh$'   # protected method scripts: they may be run

check_bash() {
  local cmd="$1" low s seg first second ask=0
  low="$(lower "$cmd")"

  # 0. Agent role: the coordinator and the planner do not use Bash.
  case "$AGENT" in
    sdd-coordinator|sdd-planner) role_block "Agent $AGENT does not run commands: $cmd" ;;
  esac

  # 1. Tools that can remove protections or reinstall the method.
  if grep -Eq '(^|[^a-z0-9_])(chflags|chmod|chown|xattr|sudo|doas)([^a-z0-9_]|$)|sdd-kit|promote\.sh|lock\.sh|install\.sh' <<<"$low"; then
    block "The command uses a tool that can remove the protections: $cmd"
  fi

  # 1a. Setting up MCP servers gives the agent new tools: only the user does that.
  if grep -Eq '(^|[^a-z0-9_])(claude|opencode)[[:space:]]+mcp([^a-z0-9_]|$)' <<<"$low"; then
    block "MCP servers are set up by the user, not by the agent. Command: $cmd"
  fi

  # 1d. git is read-only; commits, pushes and any other repository change are made by the
  #     user. No gh (GitHub CLI) either. The command of each part of the line is checked.
  local gw gsub gskip
  while IFS= read -r seg; do
    read -r -a gw <<<"$seg" || true
    [[ ${#gw[@]} -eq 0 ]] && continue
    gskip=0; gsub=""
    for w in "${gw[@]}"; do
      w="${w#(}"
      if [[ $gskip -eq 1 ]]; then gskip=0; continue; fi
      if [[ -z "$gsub" ]]; then        # looking for the command
        [[ "$w" == *=* || "${w##*/}" =~ ^(env|command|exec|nohup|time|xargs)$ ]] && continue
        case "${w##*/}" in
          gh) block "Agents do not use GitHub (gh): the user does. Command: $cmd" ;;
          git) gsub="git"; continue ;;
          *) break ;;
        esac
      else                             # after "git": skip global options up to the subcommand
        case "$w" in
          -c|-C|--git-dir|--work-tree|--namespace) gskip=1; continue ;;
          -*) continue ;;
        esac
        [[ "$w" =~ ^(status|diff|log|show|blame|ls-files|rev-parse|describe|shortlog|grep|cat-file)$ ]] \
          || block "git is read-only (status, diff, log, show…): commits and repository changes are made by the user. Command: $cmd"
        break
      fi
    done
  done < <(tr '|;&' '\n\n\n' <<<"$low")

  # 1e. Nothing is deleted for good: rm, unlink, shred and find -delete are replaced by trash
  #     (macOS Trash; files can be recovered). The command of each part of the line is checked.
  local tw tname
  while IFS= read -r seg; do
    read -r -a tw <<<"$seg" || true
    [[ ${#tw[@]} -eq 0 ]] && continue
    for w in "${tw[@]}"; do
      w="${w#(}"; tname="${w##*/}"
      [[ "$w" == *=* || "$tname" =~ ^(env|command|exec|nohup|time|xargs|sudo)$ ]] && continue
      if [[ "$tname" =~ ^(rm|unlink|shred)$ ]] || { [[ "$tname" == find ]] && [[ " $seg " == *" -delete "* ]]; }; then
        block "Do not delete with $tname: use trash <paths> (moves them to the macOS Trash, where they can be recovered; works for folders too, no -r). Command: $cmd"
      fi
      break
    done
  done < <(tr '|;&' '\n\n\n' <<<"$low")

  # 1b. Containers only through the scripts in bin/ (they mount only app/, with no network).
  if grep -Eq '(^|[^a-z0-9_])(docker|podman|nerdctl)([^a-z0-9_]|$)' <<<"$low"; then
    block "Do not use containers directly: use the scripts in bin/. Command: $cmd"
  fi

  # 1c. Commands the profile keeps for the container (.claude/sdd-deny-commands): e.g.
  #     python or Rscript run through the scripts in bin/, never directly on the Mac.
  #     The command of each part (after |, ;, &) is checked, not every word.
  if [[ -f "$DENY_FILE" ]]; then
    local deny words w name
    deny="$(grep -v '^[[:space:]]*#' "$DENY_FILE" | tr '[:upper:]' '[:lower:]' | tr -d ' \t\r')"
    while IFS= read -r seg; do
      read -r -a words <<<"$seg" || true
      [[ ${#words[@]} -eq 0 ]] && continue
      for w in "${words[@]}"; do
        w="${w#(}"
        name="${w##*/}"
        # skip assignments (VAR=value) and wrappers that run another command
        [[ "$w" == *=* || "$name" =~ ^(env|command|exec|nohup|time|xargs)$ ]] && continue
        if [[ -n "$name" ]] && grep -qxF "$name" <<<"$deny"; then
          block "\"$name\" does not run on the Mac: use the scripts in bin/ (e.g. bin/py.sh). Command: $cmd"
        fi
        break
      done
    done < <(tr '|;&' '\n\n\n' <<<"$low")
  fi

  # 2. If it does not mention protected paths, it is allowed.
  # bin/ only counts as the project folder (at the start of a word, or after ./ or ../),
  # not /bin/bash, /usr/bin/env or app/bin/.
  #    The reviewer never skips step 3: only reads and bin/ scripts, always.
  if [[ "$AGENT" != sdd-reviewer ]]; then
    grep -Eq "\.claude|\.opencode|\.agents|\.codex|opencode\.json|\.mcp\.json|(^|[[:space:]\"'=;&|(])(\.\.?/)*bin/|constitution\.md|agents\.md|claude\.md" <<<"$low" || return 0
  fi

  # 3. It mentions protected paths: read-only, no redirections or subcommands.
  s="$(sed -E 's/[0-9]*>&[0-9]+//g; s#[0-9]*>[[:space:]]*/dev/null##g' <<<"$low")"
  if grep -Eq '>|`|\$\(|(^|[^a-z])tee([^a-z]|$)' <<<"$s"; then
    block_protected "Write or subcommand on a protected path: $cmd"
  fi
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"
    [[ -z "$seg" ]] && continue
    first="${seg%%[[:space:]]*}"
    if [[ "$first" =~ $TOOL_SCRIPT ]]; then
      # Convention: --net gives the container network access; always ask the user to approve.
      [[ " $seg " == *" --net "* ]] && ask=1
      continue
    elif [[ "$first" == git ]]; then
      second="$(awk '{print $2}' <<<"$seg")"
      [[ "$second" =~ ^(diff|log|status|show|blame)$ ]] || block_protected "git command not allowed on a protected path: $cmd"
    elif [[ "$first" == find ]]; then
      grep -Eq -- '-(exec|execdir|ok|okdir|delete|fprint|fprintf|fls)' <<<"$seg" && block_protected "find with actions on a protected path: $cmd"
    elif ! [[ "$first" =~ $READ_ONLY ]]; then
      block_protected "Only reads are allowed on protected paths: $cmd"
    fi
  done < <(tr '|;&' '\n\n\n' <<<"$s")

  # Codex does not support "ask" in the hook: there the prompt rule in .codex/rules/sdd.rules asks.
  if [[ $ask -eq 1 && $IS_CLAUDE -eq 1 ]]; then
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"SDD: --net gives the container network access. Do you approve?"}}'
    exit 0
  fi
  return 0
}

TOOL="$(field tool_name)" || block "Neither jq nor python3 is available to check the request."
AGENT="$(lower "$(field agent_type)")"   # empty in a normal session, with no agent

# Project root: CLAUDE_PROJECT_DIR (Claude Code) or, in Codex, the first folder from "cwd"
# upwards that contains .codex/ or .claude/.
if [[ $IS_CLAUDE -eq 1 ]]; then
  PROJECT="$CLAUDE_PROJECT_DIR"; REL_BASE="$PROJECT"
else
  start="$(field cwd)"; [[ -n "$start" ]] || start="$PWD"
  PROJECT="$start"; REL_BASE="$start"; d="$start"
  while [[ "$d" != "/" && -n "$d" ]]; do
    if [[ -d "$d/.codex" || -d "$d/.claude" ]]; then PROJECT="$d"; break; fi
    d="$(dirname "$d")"
  done
fi
DENY_FILE="$PROJECT/.claude/sdd-deny-commands"     # installed by the profile (deny-commands)
[[ -f "$DENY_FILE" ]] || DENY_FILE="$PROJECT/.codex/sdd-deny-commands"

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit) check_edit "$(field file_path)" ;;
  Bash) check_bash "$(field command)" ;;
  apply_patch)   # Codex: the paths are inside the patch (Add/Update/Delete File, Move to)
    while IFS= read -r p; do
      [[ -n "$p" ]] && check_edit "$p"
    done < <(field command | sed -nE -e 's/^\*\*\* (Add|Update|Delete) File: //p' -e 's/^\*\*\* Move to: //p') ;;
esac
exit 0
