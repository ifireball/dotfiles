---
name: ghq-repo-helper
description: Helps find, clone, and manage repositories using the ghq command-line tool and ~/src directory structure. Trigger on requests related to finding, cloning, or managing git repositories or workspaces.
---

# GHQ Repository Helper Skill

This skill helps the agent find, clone, and manage git repositories using the user's preferred directory structure managed by `ghq`.

## Guidelines for the Agent

1. **Repository Layout**:
   - All repositories are organized in a structured tree under the user's `ghq` root, which is `~/src` (resolves to `/var/home/bkorren/src`).
   - The directory layout follows the pattern: `~/src/<hostname>/<owner>/<repository>`.
   - Example: `https://github.com/google-antigravity/antigravity-sdk-python` is located at `/var/home/bkorren/src/github.com/google-antigravity/antigravity-sdk-python`.

2. **Finding Local Repositories**:
   - Before cloning a repository, check if it already exists locally.
   - Run `ghq list --full-path` to see all local repositories, or filter them using grep.
   - Example command: `ghq list --full-path | grep -i <repo-name>`

3. **Cloning Repositories**:
   - **Do NOT** use `git clone` directly.
   - **Always** use `ghq get` to clone new repositories so they are placed in the correct directory structure automatically.
   - Example command: `ghq get https://github.com/user/repo` or `ghq get user/repo` (defaults to GitHub).

4. **Working with Repositories**:
   - Once a repository is found or cloned, perform all subsequent operations (running commands, editing files, etc.) inside the repository's path under `~/src`.
   - Recommend the user to set the repository directory as their active workspace when starting work on a repository.
