dotfiles
--------

My dotfiles, managed by [chezmoi][cz]

To install *chezmoi* and the files on a new machine:

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/ifireball/dotfiles/main/install_chezmoi.sh)" -- init --apply --ssh ifireball
```

[cz]: https://www.chezmoi.io/

### Cursor src-mirror (ghq layout)

After `chezmoi apply`, verify clone layout and scripts:

```bash
~/.cursor/skills/src-mirror-layout/scripts/verify-src-mirror.sh --all
```

Paste `~/.cursor/user-rules/src-mirror.txt` into **Cursor Settings → Rules for AI**.
