# git hooks
A personal collection of git hooks.

## How to use?

Windows Powershell/Unix/macOS:
```
HOOKS_REPO="$HOME/.git-global-hooks"
git clone --depth=1 git@github.com:tizee/git-hooks.git "$HOOKS_REPO"
git config --global core.hooksPath "$HOOKS_REPO/hooks"
```

