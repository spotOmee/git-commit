# 🚀 Git Commit (Zero-Storage-Bloat Cloud Sync)

An autonomous AI agent skill that synchronizes local coding projects directly to GitHub, auto-generates comprehensive project documentation (`README.md`), protects against secrets and large-file leaks, and **deletes local `.git` metadata immediately after a successful push** to eliminate Git storage bloat on mobile devices, PRoot Ubuntu, and Termux environments.

---

## ⚡ Why This Skill?

When coding on Android (via Termux, PRoot, or AndroidIDE) or low-capacity storage:
1. **`.git` Bloat:** Git repositories store packed objects, loose commit trees, and historical diffs locally. Over time, `.git` folders grow to gigabytes, consuming critical phone storage and slowing down mobile file indexing.
2. **Zero Local Overhead:** By shallow-fetching (`--depth 1`) only when syncing and wiping the local `.git` directory once the push succeeds, **100% of your device storage remains free of Git object history** while GitHub retains the full cloud commit log.
3. **Safe Additive Sync:** Default sync mode protects files you previously pushed to GitHub and then deleted from your device to save space—they are never accidentally deleted from the remote repository.

---

## 🛠 Features & Safeguards

- **🔍 Smart Repository Routing:** Automatically detects whether the target repository is brand new, empty, or an active repository with existing history.
- **🛡 Secret & Credential Leak Scanner:** Scans staged files for sensitive tokens (`ghp_`, `github_pat_`, `AIzaSy`, Telegram bot tokens, `.env`, `.keystore`) before staging or pushing.
- **📦 50 MB File Gatekeeper:** Automatically detects files larger than 50 MB (e.g., compiled `.apk` or zip archives) to prevent GitHub push rejections (`GH001`).
- **📝 Intelligent Documentation Generator:** Automatically analyzes the codebase (`AndroidManifest.xml`, `package.json`, Gradle files, Python requirements, entry points) and generates a clean, informative `README.md` and repository description for new projects.
- **🧹 Fail-Closed `.git` Cleanup:** The local `.git` metadata is deleted **only if `git push` exits with code 0**. If network or build issues occur, `.git` is never removed, safeguarding your uncommitted code.
- **🔒 Dedicated System Immunity:** Strictly respects and never modifies the `/home/antigravity-BRAIN` session memory repository.

---

## 📱 How to Trigger in Your Agent

Trigger this skill anytime in conversation using slash commands or plain natural language:

- `/git-commit`
- `/git commit`
- `/git-commit <repo-name>` (e.g., `/git-commit blender-android`)
- `push this project to github and clean git storage`
- `commit and upload this folder to github with zero storage bloat`

---

## 🤖 Give This Prompt to Your Coding Agent to Install

Simply copy the prompt below and paste it directly into your AI coding agent (Antigravity, Claude Code, Cursor, Codex, OpenCode, etc.):

```markdown
Please install the `git-commit` skill globally so you can sync projects to GitHub with zero local storage bloat:

1. Clone or pull the skill from GitHub:
   git clone --depth 1 https://github.com/spotOmee/git-commit.git ~/.agents/skills/git-commit || git -C ~/.agents/skills/git-commit pull

2. Run its installer or symlink it:
   bash ~/.agents/skills/git-commit/install.sh

3. Verify SKILL.md is registered:
   ls -la ~/.agents/skills/git-commit/SKILL.md
```

---

## 💻 One-Line Shell Install (Direct CLI)

If you prefer installing directly from your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/spotOmee/git-commit/main/install.sh | bash
```

Or clone manually:

```bash
git clone --depth 1 https://github.com/spotOmee/git-commit.git ~/.agents/skills/git-commit
bash ~/.agents/skills/git-commit/install.sh
```

---

## 📋 Supported Sync Scenarios

| Scenario | Trigger / Condition | Workflow |
| :--- | :--- | :--- |
| **A: New Repository** | Remote repo does not exist on GitHub | Creates private repo via `gh repo create`, generates `.gitignore` & `README.md`, pushes, and purges `.git`. |
| **B: Empty Existing Repo** | Remote repo exists but has no commits | Links remote, generates docs if missing, pushes initial commit, and purges `.git`. |
| **C: Shallow Update Existing** | Remote repo has existing code | Shallow fetches latest commit pointer (`--depth 1`), performs additive safe sync of new/modified files, pushes, and purges `.git`. |

---

## 📄 License

MIT License. Free to use, modify, and distribute.
