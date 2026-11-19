#!/usr/bin/env bash
set -e

SKILL_NAME="git-commit"
REPO_URL="https://github.com/spotOmee/git-commit.git"

echo "==> Installing ${SKILL_NAME} globally..."

# Resolve script directory or clone if executed via curl | bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
  CANONICAL_DIR="$HOME/.agents/skills/${SKILL_NAME}"
  if [ -d "$CANONICAL_DIR/.git" ]; then
    echo "Updating existing installation in $CANONICAL_DIR..."
    git -C "$CANONICAL_DIR" pull --rebase || true
  else
    echo "Cloning ${SKILL_NAME} to $CANONICAL_DIR..."
    mkdir -p "$HOME/.agents/skills"
    git clone --depth 1 "$REPO_URL" "$CANONICAL_DIR"
  fi
  SCRIPT_DIR="$CANONICAL_DIR"
fi

TARGET_DIRS=(
  "$HOME/.agents/skills/${SKILL_NAME}"
  "$HOME/.gemini/skills/${SKILL_NAME}"
  "$HOME/.gemini/config/skills/${SKILL_NAME}"
  "$HOME/.claude/skills/${SKILL_NAME}"
)

# Common aliases
ALIASES=(
  "git_commit"
  "gitcommit"
  "Git_commit_skill"
  "Git_commit_skill.md"
)

mkdir -p "$HOME/.agents/skills"
if [ "$SCRIPT_DIR" != "$HOME/.agents/skills/${SKILL_NAME}" ]; then
  ln -sfn "$SCRIPT_DIR" "$HOME/.agents/skills/${SKILL_NAME}"
  echo "[✔] Installed to $HOME/.agents/skills/${SKILL_NAME}"
fi

for TARGET in "${TARGET_DIRS[@]}"; do
  PARENT_DIR="$(dirname "$TARGET")"
  if [ -d "$PARENT_DIR" ] && [ "$SCRIPT_DIR" != "$TARGET" ]; then
    ln -sfn "$SCRIPT_DIR" "$TARGET"
    echo "[✔] Linked to $TARGET"
  fi
done

# Create convenient aliases
for ALIAS in "${ALIASES[@]}"; do
  ln -sfn "$SCRIPT_DIR" "$HOME/.agents/skills/${ALIAS}"
  [ -d "$HOME/.gemini/skills" ] && ln -sfn "$SCRIPT_DIR" "$HOME/.gemini/skills/${ALIAS}"
  [ -d "$HOME/.gemini/config/skills" ] && ln -sfn "$SCRIPT_DIR" "$HOME/.gemini/config/skills/${ALIAS}"
  [ -d "$HOME/.claude/skills" ] && ln -sfn "$SCRIPT_DIR" "$HOME/.claude/skills/${ALIAS}"
done

echo ""
echo "🎉 Skill '${SKILL_NAME}' successfully installed!"
echo "Trigger it with: /git-commit, /git commit, or 'push this project to github with zero storage bloat'."
