#!/usr/bin/env bash
# Tests for the protect.sh hook. Usage: tests/test-protect.sh   (needs jq)
# Creates a temporary project, feeds it sample requests and checks whether they are blocked.
set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$KIT_DIR/protect/protect.sh"
S="$(mktemp -d "${TMPDIR:-/tmp}/sdd-hooktest.XXXX")"
mkdir -p "$S"/{app,specs/001,docs/proposals,.claude,bin}
touch "$S/AGENTS.md" "$S/docs/constitution.md" "$S/bin/run.sh"
ln -s ../AGENTS.md "$S/app/link.md"
printf '# profile commands\npython\npython3\npip\nuv\nRscript\n' > "$S/.claude/sdd-deny-commands"

pass=0; fail=0
t() { # t BLOCK|ALLOW|ASK <tool> <value> [agent]
  local exp=$1 tool=$2 val=$3 agent=${4:-} json rc got out
  case "$tool" in
    Bash) json=$(jq -nc --arg v "$val" '{tool_name:"Bash",tool_input:{command:$v}}') ;;
    NotebookEdit) json=$(jq -nc --arg v "$val" '{tool_name:"NotebookEdit",tool_input:{notebook_path:$v}}') ;;
    *) json=$(jq -nc --arg t "$tool" --arg v "$val" '{tool_name:$t,tool_input:{file_path:$v}}') ;;
  esac
  [[ -n "$agent" ]] && json=$(jq -c --arg a "$agent" '. + {agent_type: $a}' <<<"$json")
  out=$(CLAUDE_PROJECT_DIR="$S" "$HOOK" <<<"$json" 2>/dev/null); rc=$?
  if [[ $rc == 2 ]]; then got=BLOCK
  elif [[ "$out" == *'"permissionDecision":"ask"'* ]]; then got=ASK
  else got=ALLOW; fi
  if [[ $got == "$exp" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%s %-5s %-12s %s%s\n' "$([[ $got == "$exp" ]] && echo ✅ || echo ❌)" "$got" "$tool" \
    "${val#"$S"/}" "${agent:+   [$agent]}"
}

echo "— Editing protected files"
t BLOCK Edit AGENTS.md
t BLOCK Write "$S/agents.md"
t BLOCK Edit "$S/app/../CLAUDE.md"
t BLOCK Write "$S/.claude/settings.json"
t BLOCK Write "$S/.claude/agents/new/x.md"
t BLOCK Write "$S/docs/constitution.md"
t BLOCK Edit "$S/app/link.md"
t BLOCK Write "$S/app/new/../../AGENTS.md"
t BLOCK NotebookEdit "$S/.opencode/x.ipynb"
t BLOCK Write "$S/bin/run.sh"
t BLOCK Write "$S/bin/new.sh"
t BLOCK Write "$S/.mcp.json"
t BLOCK Edit ".MCP.json"
echo "— Allowed edits"
t ALLOW Write "$S/app/main.py"
t ALLOW Write "$S/app/bin/helper.R"
t ALLOW Write "$S/specs/001/spec.md"
t ALLOW Write "$S/docs/proposals/constitution.md"
t ALLOW Edit MEMORY.md
echo "— Allowed Bash"
t ALLOW Bash "cat AGENTS.md"
t ALLOW Bash "grep -n RF docs/constitution.md | head -5"
t ALLOW Bash "git diff AGENTS.md 2>&1"
t ALLOW Bash "ls -la .claude"
t ALLOW Bash "cat bin/run.sh"
t ALLOW Bash "bin/run.sh Rscript tests/testthat.R"
t ALLOW Bash "./bin/bootstrap.sh"
t ALLOW Bash "bin/run.sh Rscript -e 'targets::tar_make()' 2>&1 | tail -5"
t ALLOW Bash "cd app && ls R"
t ALLOW Bash "bin/run.sh Rscript -e 'x <- \"--network\"'"
t ALLOW Bash "/bin/bash -c 'echo hola' > /tmp/salida.txt"
t ALLOW Bash "/usr/bin/env ls > app/out.txt"
t ALLOW Bash "ls /usr/local/bin/air > app/lista.txt"
t ALLOW Bash "echo x > app/bin/notas.txt"
echo "— MCP: only the user sets it up"
t BLOCK Bash "claude mcp add --scope project chrome -- npx chrome-devtools-mcp@latest"
t BLOCK Bash "opencode mcp add x"
t BLOCK Bash "echo '{}' > .mcp.json"
t ALLOW Bash "cat .mcp.json"
t ALLOW Bash "grep -n claude app/README.md"
echo "— Profile commands (sdd-deny-commands): only inside the container"
t BLOCK Bash "python3 x.py"
t BLOCK Bash "cd app && uv run pytest"
t BLOCK Bash "/opt/homebrew/bin/python3 -m http.server"
t BLOCK Bash "/usr/bin/env python3 app/x.py"
t BLOCK Bash "env FOO=1 python x.py"
t BLOCK Bash "PYTHONPATH=src python -m x"
t BLOCK Bash "pip install requests"
t BLOCK Bash "(cd app; Rscript x.R)"
t ALLOW Bash "bin/py.sh uv run pytest -q"
t ALLOW Bash "echo python"
t ALLOW Bash "grep -rn uv app/src"
t ALLOW Bash "ls app | grep python"
echo "— Bash that asks for approval (--net)"
t ASK Bash "bin/run.sh --net Rscript -e 'renv::install(\"x\")'"
t ASK Bash "./bin/bootstrap.sh --net"
echo "— Blocked Bash"
t BLOCK Bash "echo x >> AGENTS.md"
t BLOCK Bash "sed -i '' 's/a/b/' .claude/settings.json"
t BLOCK Bash "cat docs/constitution.md | tee /tmp/x"
t BLOCK Bash "unlink CLAUDE.md"
t BLOCK Bash "mv CLAUDE.md /tmp/"
t BLOCK Bash "git checkout AGENTS.md"
t BLOCK Bash "find .claude -delete"
t BLOCK Bash "python3 -c \"open('AGENTS.md','w')\""
t BLOCK Bash "chflags -R nouchg ."
t BLOCK Bash "cd app; sudo ls"
t BLOCK Bash "../sdd-kit/promote.sh . agents"
t BLOCK Bash "cat \$(echo AGENTS.md)"
t BLOCK Bash "echo x > bin/run.sh"
t BLOCK Bash "cp /tmp/x.sh bin/run.sh"
t BLOCK Bash "bash bin/run.sh"
t BLOCK Bash "docker run --rm -v /:/host alpine ls /host"
t BLOCK Bash "cd app && podman ps"
t BLOCK Bash "bin/run.sh Rscript x.R > out.txt"
t BLOCK Bash "echo x > ./bin/run.sh"
t BLOCK Bash "cd app && rm ../bin/run.sh"
t BLOCK Bash "/bin/bash bin/run.sh"

echo "— git read-only; no gh"
t ALLOW Bash "git status"
t ALLOW Bash "git log --oneline -5"
t ALLOW Bash "git -C app diff --stat"
t ALLOW Bash "git show HEAD:app/x.py"
t BLOCK Bash "git commit -m 'cambios'"
t BLOCK Bash "git push origin main"
t BLOCK Bash "git -C app commit -am x"
t BLOCK Bash "cd app && git add . && git commit -m x"
t BLOCK Bash "git reset --hard HEAD~1"
t BLOCK Bash "git stash"
t BLOCK Bash "GIT_AUTHOR_NAME=x git commit -m y"
t BLOCK Bash "/usr/bin/git push"
t BLOCK Bash "gh pr create --fill"
t ALLOW Bash "echo 'no hagas git commit'"
t ALLOW Bash "grep -rn 'git push' docs"
echo "— Deleting: to the Trash (trash), never rm"
t BLOCK Bash "rm app/x.py"
t BLOCK Bash "rm -rf app/build"
t BLOCK Bash "cd app && rm -f *.tmp"
t BLOCK Bash "/bin/rm app/x"
t BLOCK Bash "find app -name '*.pyc' | xargs rm"
t BLOCK Bash "find app -name '*.pyc' -delete"
t BLOCK Bash "unlink app/x.py"
t ALLOW Bash "trash app/x.py app/build"
t ALLOW Bash "echo 'no uses rm'"
t ALLOW Bash "grep -rn 'rm -rf' app"
t ALLOW Bash "find app -name '*.pyc'"
t ALLOW Bash "rmdir app/vacia"
echo "— Agent roles (agent_type)"
t BLOCK Write "$S/app/x.py" sdd-coordinator
t BLOCK Bash "ls" sdd-coordinator
t ALLOW Write "$S/specs/001/spec.md" sdd-planner
t BLOCK Write "$S/app/x.py" sdd-planner
t BLOCK Write "$S/MEMORY.md" sdd-planner
t BLOCK Write "/tmp/fuera.txt" sdd-planner
t BLOCK Bash "cat app/x.py" sdd-planner
t ALLOW Write "$S/app/src/x.py" sdd-implementer
t ALLOW Edit "$S/specs/001/tasks.md" sdd-implementer
t ALLOW Edit "$S/MEMORY.md" sdd-implementer
t BLOCK Edit "$S/specs/001/spec.md" sdd-implementer
t BLOCK Write "$S/README.md" sdd-implementer
t BLOCK Write "$S/AGENTS.md" sdd-implementer
t ALLOW Bash "bin/run.sh Rscript tests/testthat.R" sdd-implementer
t ALLOW Bash "echo x > app/out.txt" sdd-implementer
t BLOCK Edit "$S/app/x.py" sdd-reviewer
t ALLOW Bash "bin/check.sh" sdd-reviewer
t ALLOW Bash "git diff --stat" sdd-reviewer
t ALLOW Bash "cat app/src/x.py | head -20" sdd-reviewer
t BLOCK Bash "echo x > app/out.txt" sdd-reviewer
t BLOCK Bash "rm app/x.py" sdd-reviewer
t BLOCK Bash "git checkout app/x.py" sdd-reviewer
t ALLOW Write "$S/app/x.py"
t ALLOW Bash "echo x > app/out.txt"

echo "— Codex (no CLAUDE_PROJECT_DIR; root from cwd; edits with apply_patch)"
tc() { # tc BLOCK|ALLOW <tool> <command or patch> [cwd]
  local exp=$1 tool=$2 val=$3 cwd=${4:-$S} json rc got
  json=$(jq -nc --arg t "$tool" --arg v "$val" --arg c "$cwd" '{tool_name:$t,tool_input:{command:$v},cwd:$c}')
  (cd /tmp && env -u CLAUDE_PROJECT_DIR "$HOOK" <<<"$json" >/dev/null 2>&1); rc=$?
  got=$([[ $rc == 2 ]] && echo BLOCK || echo ALLOW)
  if [[ $got == "$exp" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%s %-5s %-12s %s\n' "$([[ $got == "$exp" ]] && echo ✅ || echo ❌)" "$got" "$tool" "$(head -c 70 <<<"${val//$'\n'/ ⏎ }")"
}
P=$'*** Begin Patch\n'
tc ALLOW apply_patch "${P}*** Add File: app/x.py"$'\n+x\n*** End Patch'
tc BLOCK apply_patch "${P}*** Update File: AGENTS.md"$'\n@@\n-a\n+b\n*** End Patch'
tc BLOCK apply_patch "${P}*** Add File: .codex/config.toml"$'\n+x\n*** End Patch'
tc BLOCK apply_patch "${P}*** Add File: app/ok.py"$'\n+x\n'"*** Delete File: bin/run.sh"$'\n*** End Patch'
tc BLOCK apply_patch "${P}*** Update File: app/x.py"$'\n'"*** Move to: bin/x.sh"$'\n@@\n*** End Patch'
tc ALLOW apply_patch "${P}*** Update File: x.py"$'\n@@\n-a\n+b\n*** End Patch' "$S/app"
tc BLOCK apply_patch "${P}*** Update File: ../AGENTS.md"$'\n@@\n-a\n+b\n*** End Patch' "$S/app"
tc BLOCK Bash "python3 x.py" "$S/app"
tc BLOCK Bash "git commit -m x"
tc ALLOW Bash "bin/run.sh --net uv add httpx"
tc ALLOW Bash "ls app"

echo "Result: $pass passed, $fail failed."
[[ $fail -eq 0 ]]
