---
name: git-commit
description: Zero-storage-bloat cloud sync manager for GitHub. Trigger whenever the user types `/git-commit`, `/git commit`, or asks to push a project to a new or existing GitHub repository (by name or keyword), auto-generate README documentation, safeguard secrets/large files, and delete local `.git` metadata afterward to save phone storage.
---
# Git Commit (Zero-Storage-Bloat Cloud Sync)

Push local projects to GitHub cleanly, auto-generate project documentation (`README.md`), prevent secret or large-file leaks, and remove local `.git` history afterward so your phone storage stays completely free of Git object bloat.

## Supported Scenarios

1. **New Repository (Does Not Exist on GitHub):** Creates a private GitHub repository with an auto-generated description, scans the codebase to generate a comprehensive `README.md` and smart `.gitignore`, pushes everything, and removes local `.git`.
2. **Empty Existing Repository:** Links the local folder to the empty remote repository, generates `README.md` and `.gitignore` if missing, pushes the initial codebase, and removes local `.git`.
3. **Active Existing Repository (Has Code & History):** Performs a shallow metadata sync (`--depth=1`) so old history is never downloaded onto the phone, commits only new/modified files (preserving existing remote files unless `--mirror` is requested), pushes, and removes local `.git`.

---

## 🤖 Give This Prompt to Your Coding Agent to Install

Anyone who wants to install this skill into their coding agent (Antigravity, Claude Code, Cursor, OpenCode, Codex, Gemini CLI) just needs to copy and paste the prompt below:

```markdown
Please install the `git-commit` skill globally so you can sync projects to GitHub with zero local storage bloat:

1. Clone or pull the skill repository:
   git clone --depth 1 https://github.com/spotOmee/git-commit.git ~/.agents/skills/git-commit || git -C ~/.agents/skills/git-commit pull

2. Run the global installer:
   bash ~/.agents/skills/git-commit/install.sh

3. Verify installation:
   ls -la ~/.agents/skills/git-commit/SKILL.md
```

### 💻 Quick One-Line Shell Command (Direct CLI)

```bash
curl -fsSL https://raw.githubusercontent.com/spotOmee/git-commit/main/install.sh | bash
```

---

## Step 1: Pre-Flight Auth & Identity Check

Verify `git` and `gh` CLI authentication before touching files:

```bash
git --version && gh auth status
```

- Ensure Git identity is configured (`git config user.name` and `git config user.email`). If missing, configure fallback identity from the authenticated GitHub profile (`gh api user`).
- If `gh auth status` fails, stop and ask the user to run `gh auth login`.

---

## Step 2: Resolve Target Repository Name & Sync Mode

1. **Extract Target Name:**
   - If the user passes a name/keyword (e.g., `/git-commit blender-android`), sanitize it to a lowercase-hyphenated repository slug (`blender-android`).
   - If no name is given, derive the slug from the current directory name (`basename "$PWD"`).
   - Check if the user passed `--mirror` or `--clean` (full sync including remote deletions) vs. default **Additive Sync** (safe mode that never deletes existing remote files that were cleaned off local storage).

2. **Check Remote Repository State:**
   ```bash
   gh repo view "<owner>/<repo-slug>" --json name,isEmpty,defaultBranchRef,url 2>/dev/null
   ```
   - **If command fails (404 / Not Found):** Route to **Scenario A (Create New Repo)**.
   - **If `isEmpty == true`:** Route to **Scenario B (Initialize Empty Repo)**.
   - **If `isEmpty == false`:** Route to **Scenario C (Shallow Update Existing Repo)**.

---

## Step 3: Smart `.gitignore`, Secret Guard & 50 MB File Check

Before initializing Git or staging any files, run these mandatory safeguards:

1. **Inject Smart `.gitignore` (if missing):** Auto-detect project stack (Android/Gradle, Node/JS, Python, C/C++) and ensure heavy build caches and local configs are ignored:
   ```gitignore
   # Build & Cache Artifacts
   build/
   **/build/
   .gradle/
   node_modules/
   __pycache__/
   *.pyc
   .cxx/
   .externalNativeBuild/

   # Device & Local IDE Paths
   local.properties
   .idea/
   *.iml
   .DS_Store

   # Secrets & Signing Keys
   .env
   .env.*
   *.keystore
   *.jks
   *.p12
   *.pem
   *.key
   *.pk8
   id_rsa*
   id_ed25519*
   secrets.*
   ```

2. **Secret & Credential Leak Scanner:**
   - Verify no `.env`, `*.keystore`, `*.jks`, or `google-services.json` containing private credentials is being staged unless explicitly requested.
   - Scan text files for accidental hardcoded tokens (`ghp_`, `github_pat_`, `AIzaSy`, or Telegram bot tokens matching `[0-9]{8,10}:[A-Za-z0-9_-]{35}`). If found, warn the user and exclude or redact before pushing.

3. **Large File Guard (> 50 MB):**
   - Check for any unignored file larger than 50 MB (`find . -not -path '*/.*' -type f -size +50M`).
   - If found, list the oversized files and ask whether to exclude them (e.g., compiled `.apk` or `.zip` archives) so GitHub does not reject the push (`GH001: Large files detected`).

---

## Step 4: Auto-Generate `README.md` & Repo Metadata

- **For Scenario A (New Repo) & Scenario B (Empty Repo):**
  1. Inspect key project files (`AndroidManifest.xml`, `build.gradle*`, `package.json`, `requirements.txt`, or main source entry points).
  2. Generate a clean, well-structured `README.md` containing:
     - Project Title & Concise Summary
     - Tech Stack & Key Features
     - Directory Structure Overview
     - Setup / Build Instructions
  3. Set a clear repository description on GitHub (`gh repo edit "<owner>/<repo-slug>" --description "<summary>"`).

- **For Scenario C (Existing Repo):**
  - Keep the existing `README.md` intact unless the user explicitly asks to update documentation or major new modules were added.

---

## Step 5: Execute Zero-Bloat Sync & Push

### Mandatory Pre-Push Security & Credential Gate
Before staging or committing any files in any scenario, strictly enforce credential-free remote and safe staging:

1. **Credential-Free Remote URL Verification:**
   Ensure remote URLs never embed plaintext tokens, usernames, or passwords:
   ```bash
   REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
   if echo "$REMOTE_URL" | grep -qE "://[^@]+@"; then
     echo "❌ Token embedded in remote URL! Sanitizing..."
     CLEAN_URL=$(echo "$REMOTE_URL" | sed -E 's|://[^@]+@|://|')
     git remote set-url origin "$CLEAN_URL"
   fi
   ```
   Always rely on system credential helpers (`gh auth git-credential`) or SSH agent forwarding.

2. **Safe Staging & Diff Verification:**
   Never perform blind `git add -A` without verifying against sensitive patterns:
   ```bash
   # Check unignored secrets before staging
   git status --porcelain | grep -E "\.(keystore|jks|pem|key|p12|pk8|env)$|local\.properties" && {
     echo "❌ SENSITIVE FILES UNIGNORED! Adding to .gitignore..."
     echo -e "\n*.keystore\n*.jks\n*.pem\n*.key\nlocal.properties\n.env\n.env.*" >> .gitignore
   }
   ```
   After staging, audit `git diff --cached`:
   ```bash
   # Scan staged diff for sensitive patterns before commit
   python3 -c '
   import subprocess, sys, re
   diff = subprocess.check_output(["git", "diff", "--cached"]).decode("utf-8", errors="ignore")
   patterns = [
       (r"-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----", "Private Key"),
       (r"\b[0-9]{8,10}:[a-zA-Z0-9_-]{35}\b", "Telegram Bot Token"),
       (r"(?i)\b(?:ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}\b", "GitHub Token"),
       (r"(?i)\bgithub_pat_[a-zA-Z0-9_]{30,}\b", "GitHub PAT"),
   ]
   for pat, desc in patterns:
       if re.search(pat, diff):
           print(f"❌ CRITICAL: Staged diff contains sensitive {desc}! Aborting push.")
           sys.exit(1)
   '
   ```

3. **Clean Semantic Commit Messages:**
   Commit messages must never contain environment variables, home directory paths, system usernames, or key hashes. Use clean semantic messages (e.g. `feat: update app navigation and models`).

---

### Scenario A: Create New Repo & Push
```bash
git init -b main
git add .
python3 -c '... diff check ...'
git commit -m "feat: initial project upload with documentation"
gh repo create "<repo-slug>" --private --source=. --remote=origin --push
```

### Scenario B: Initialize Empty Existing Repo & Push
```bash
git init -b main
git remote add origin "https://github.com/<owner>/<repo-slug>.git"
git add .
python3 -c '... diff check ...'
git commit -m "feat: initial project upload"
git push -u origin main
```

### Scenario C: Shallow Sync & Update Existing Repo (No History Download)
To avoid downloading gigabytes of commit history onto the phone while still preserving remote commit history:

```bash
git init -b main
git remote add origin "https://github.com/<owner>/<repo-slug>.git"

# Fetch only the latest commit pointer (zero historical blob bloat)
DEFAULT_BRANCH=$(gh repo view "<owner>/<repo-slug>" --json defaultBranchRef --jq '.defaultBranchRef.name')
git checkout -B "$DEFAULT_BRANCH"
git fetch --depth=1 origin "$DEFAULT_BRANCH"

# Align index with remote HEAD without overwriting local working files
git reset --soft "origin/$DEFAULT_BRANCH"
```

- **Default (Additive Safe Sync):** Stage new and modified local files without deleting remote files that are absent locally:
  ```bash
  git restore --staged .
  git add -A --ignore-removal
  ```
- **If `--mirror` / `--clean` flag was requested:** Stage exact local state including deletions:
  ```bash
  git add -A
  ```
- **Commit & Push with Meaningful Summary:**
  Inspect `git diff --cached --stat` and commit with a clear, conventional message (e.g., `feat: update app UI and background sync logic`):
  ```bash
  if ! git diff --cached --quiet; then
    git commit -m "<descriptive-commit-message>"
    git push origin "$DEFAULT_BRANCH"
  else
    echo "No new changes to push."
  fi
  ```

---

## Step 6: Mandatory Local `.git` Cleanup (Zero Storage Bloat)

Once `git push` exits with status `0` and remote sync is confirmed:

```bash
rm -rf .git
```

Verify `.git` is completely removed (`ls -la .git 2>/dev/null || echo "Cleaned"`) while confirming all working project files remain untouched.

---

## Step 7: Final Confirmation Report

Provide a concise completion summary to the user:
- **Repository URL:** `https://github.com/<owner>/<repo-slug>`
- **Action Taken:** Created new repo / Initialized empty repo / Updated existing repo
- **Files Synced & Commit Message:** Summary of pushed changes
- **Storage Status:** Confirmed local `.git` metadata was deleted to keep device storage clean.

## Gotchas

- **Never delete `.git` if `git push` fails:** Only run `rm -rf .git` after verifying exit code `0` from `git push` so uncommitted work is never lost.
- **Additive Sync by Default:** Because local `.git` is deleted between sessions, using `git add -A --ignore-removal` on existing repos ensures files you previously uploaded to GitHub and deleted locally to save space are NOT accidentally wiped from GitHub.
- **Preserve `gradlew` Execute Bit:** If `gradlew` is present, always run `git update-index --chmod=+x gradlew` before committing so Linux CI runners can execute it.
- **Never touch antigravity-BRAIN:** Never execute `/git-commit` on `/home/antigravity-BRAIN` or `/home/agy-sync`. That repository is strictly reserved for session memory synchronization via `/git-push`.
