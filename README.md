# 🪝 Advanced Git Hooks Collection

A sophisticated collection of git hooks designed to enhance security, code quality, and developer productivity through automated credential scanning and AI-powered commit message generation.

## 🚀 Features

### 🔐 Security-First Pre-commit Hook
- **Credential Leak Detection**: Scans for API keys, tokens, passwords, and private keys
- **Multi-pattern Recognition**: Supports AWS, Google, Stripe, and generic token formats
- **C/C++ Auto-formatting**: Automatically formats staged C/C++ files using `clang-format`
- **Bypass Controls**: Environment variable support for temporary disabling

### 🤖 AI-Powered Commit Message Generation
- **LLM Integration**: Uses `llm` CLI tool for intelligent commit message creation
- **Smart Caching**: Caches commit messages based on staged changes to avoid regeneration
- **Cross-platform**: Works on Unix, macOS, and Windows systems
- **Visual Feedback**: Customizable spinner animations during message generation
- **Safety Features**:
  - Skip modes for amending commits and merge operations
  - Automatic detection of non-interactive terminals (CI/agents)
  - Rebase operation protection (prevents rewriting historical commit messages)
  - Fallback to HEAD content when no staged changes present

## 📦 Installation

### Quick Setup (Recommended)

#### Unix/macOS
```bash
HOOKS_REPO="$HOME/.git-global-hooks"
git clone --depth=1 https://github.com/tizee/git-hooks.git "$HOOKS_REPO"
git config --global core.hooksPath "$HOOKS_REPO/hooks"
```

#### Windows (PowerShell)
```powershell
$HOOKS_REPO = "$env:USERPROFILE\.git-global-hooks"
git clone --depth=1 https://github.com/tizee/git-hooks.git "$HOOKS_REPO"
git config --global core.hooksPath "$HOOKS_REPO\hooks"
```

### Prerequisites

#### For AI Commit Messages
- Install the `llm` CLI tool:
  ```bash
  pip install llm
  # or
  brew install llm  # macOS
  ```
- Configure your preferred AI model:
  ```bash
  llm keys set openai
  llm models default gpt-4
  ```

#### For C/C++ Formatting
- Install `clang-format`:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install clang-format
  
  # macOS
  brew install clang-format
  
  # Windows (via Chocolatey)
  choco install llvm
  ```

## ⚙️ Configuration

### Environment Variables

#### Pre-commit Hook
- `SKIP_SCAN_GITHOOK=1`: Skip security scanning
- `DISABLE_SECRET_SCAN=1`: Alternative skip flag

#### Prepare-commit-msg Hook
- `LLM_GITHOOK_SKIP=1`: Skip AI commit message generation entirely
- `LLM_GITHOOK_FORCE=1`: Force regeneration even with cached/unmodified diffs
- `LLM_GITHOOK_NO_BYPASS_AMENDING=1`: Prevent bypass during commit amending (normally bypasses for amends)
- `LLM_GITHOOK_SPINNER_STYLE=style`: Set custom spinner style (defaults to `classic`, see available styles below)
- `LLM_GITHOOK_FPS=30`: Control animation FPS (default `30`)
- `LLM_GITHOOK_STATUS_TEXT="..."`: Override the animated status text
- `LLM_GITHOOK_SHIMMER_SWEEP_SECONDS=2.0`: Shimmer sweep duration in seconds
- `LLM_GITHOOK_SHIMMER_PADDING=10`: Shimmer padding in characters
- `LLM_GITHOOK_SHIMMER_BAND_WIDTH=5.0`: Shimmer band half-width in characters
- `LLM_GITHOOK_COLOR_MODE=256`: Color mode (`256` or `truecolor`)
- `LLM_GITHOOK_SHIMMER_BASE_COLOR=255`: Shimmer base text color (256-color)
- `LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR=240`: Shimmer wave color (256-color)
- `LLM_GITHOOK_SPINNER_COLOR`: Spinner color (defaults to match shimmer base)
- `LLM_GITHOOK_ALLOW_NONINTERACTIVE=1`: Allow hook to run in non-interactive terminals (CI/agents)
- `LLM_PROGRAM`: Custom path to the `llm` executable (defaults to system `llm`)
- `LLM_PREPARE_COMMIT_MSG_PROMPT`: Custom path to the prompt template file
- `PYTHONIOENCODING=utf-8`: Force Python encoding (set automatically for Windows compatibility)

### Available Spinner Styles
- `classic` (default): `|/-\`
- `dots`: `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`
- `arrows`: `←↖↑↗→↘↓↙`
- `blocks`: `▖▘▝▗`
- `pulse`: `▁▂▃▄▅▆▇█▇▆▅▄▃▂`
- `bouncing`: `⠁⠂⠄⡀⢀⠠⠐⠈`
- `circle`: `◐◓◑◒`
- `square`: `◰◳◲◱`
- `triangle`: `◴◵◶◷`
- `diamond`: `◇◈◆`

### Advanced Environment Variables

#### Custom LLM Configuration
- **LLM_PROGRAM**: Override the default `llm` command path
  ```bash
  export LLM_PROGRAM="/usr/local/bin/llm-custom"
  export LLM_PREPARE_COMMIT_MSG_PROMPT="$HOME/.config/git/commit-prompt.txt"
  ```

#### Spinner Customization
- **LLM_GITHOOK_SPINNER_STYLE**: Set spinner animation style (defaults to `classic`)
  ```bash
  # Set spinner style
  export LLM_GITHOOK_SPINNER_STYLE="dots"
  ```

#### Color Customization
The shimmer animation and spinner support configurable colors via 256-color or TrueColor modes.

**Environment Variables:**
- `LLM_GITHOOK_COLOR_MODE`: `256` (default) or `truecolor`
- `LLM_GITHOOK_SHIMMER_BASE_COLOR`: Base text color (default: `255`)
- `LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR`: Wave color (default: `240`)
- `LLM_GITHOOK_SPINNER_COLOR`: Spinner color (default: same as base)

**Accepted formats:**
- 256-color numbers: `0-255` (default mode)
- TrueColor RGB: `"R,G,B"` (requires `LLM_GITHOOK_COLOR_MODE=truecolor`)

**Presets:**
```bash
# Light base with darker wave (default 256-color)
export LLM_GITHOOK_COLOR_MODE=256
export LLM_GITHOOK_SHIMMER_BASE_COLOR=255
export LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR=240

# Darker base with lighter wave (inverted)
export LLM_GITHOOK_COLOR_MODE=256
export LLM_GITHOOK_SHIMMER_BASE_COLOR=240
export LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR=255
```

#### Bypass and Control Variables
- **LLM_GITHOOK_SKIP**: Complete bypass for AI generation
- **LLM_GITHOOK_FORCE**: Override caching behavior
- **LLM_GITHOOK_NO_BYPASS_AMENDING**: Disable automatic bypass during amend operations
- **LLM_GITHOOK_ALLOW_NONINTERACTIVE**: Allow hook to run in non-interactive terminals (CI/agents)
  ```bash
  # Skip AI for specific repositories
  export LLM_GITHOOK_SKIP=1

  # Force regeneration for debugging
  export LLM_GITHOOK_FORCE=1

  # Always run AI even when amending
  export LLM_GITHOOK_NO_BYPASS_AMENDING=1

  # Allow running in CI/automation environments
  export LLM_GITHOOK_ALLOW_NONINTERACTIVE=1
  ```

#### Automatic Safety Features
The hook automatically detects and skips execution in the following scenarios:
- **Non-interactive terminals**: Automatically skips in CI/agent environments unless `LLM_GITHOOK_ALLOW_NONINTERACTIVE` is set
- **Rebase operations**: Skips during `git rebase` to avoid rewriting historical commit messages
- **Merge commits**: Skips for merge commits to preserve merge messages
- **No staged changes**: Falls back to HEAD content when amending message-only commits

#### Windows-Specific Variables
- **PYTHONIOENCODING**: Force UTF-8 encoding (automatically set)
- **LC_ALL/LANG**: Locale settings for proper encoding
  ```bash
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  ```

### Model Name Mapping
The system automatically maps common model names for consistency:
- `doubao-v3` → `deepseek-v3`
- `doubao-r1` → `deepseek-r1`
- `siliconflow-r1` → `deepseek-r1`
- `deepseek-chat` → `deepseek-v3`
- `deepseek-reasoner` → `deepseek-r1`

## 🔍 Usage Examples

### Basic Usage
```bash
# Make changes and commit
git add .
git commit
# AI will generate commit message automatically
```

### Skip Security Scanning
```bash
# Skip credential scan for this commit
SKIP_SCAN_GITHOOK=1 git commit -m "Quick fix"

# Set for entire session
export SKIP_SCAN_GITHOOK=1
```

### Skip AI Message Generation
```bash
# Use your own commit message
LLM_GITHOOK_SKIP=1 git commit

# Bypass for amending
git commit --amend
```

### Force Regeneration
```bash
# Regenerate even if changes are cached
LLM_GITHOOK_FORCE=1 git commit --amend
```

### Custom Spinner Style
```bash
# Use dots spinner
LLM_GITHOOK_SPINNER_STYLE=dots git commit

# Set permanently in your shell profile
echo 'export LLM_GITHOOK_SPINNER_STYLE=dots' >> ~/.zshrc
```

### Allow in CI/Automation
```bash
# Enable hook in non-interactive environments
LLM_GITHOOK_ALLOW_NONINTERACTIVE=1 git commit
```

## 🛠️ Troubleshooting

### Common Issues

#### "llm command not found"
```bash
# Install llm
pip install llm

# Verify installation
llm --version
```

#### "clang-format not found"
```bash
# Install based on your system
# Ubuntu/Debian
sudo apt-get install clang-format

# macOS
brew install clang-format

# Verify installation
clang-format --version
```

#### Commit stuck on spinner
- Check network connectivity for AI service
- Verify AI model configuration: `llm models`
- Skip AI generation: `LLM_GITHOOK_SKIP=1 git commit`

#### Hook not running in CI/automation
- The hook automatically skips in non-interactive terminals
- To enable in CI: `export LLM_GITHOOK_ALLOW_NONINTERACTIVE=1`
- Verify terminal interactivity: `test -t 0 && echo "interactive" || echo "non-interactive"`

#### Hook not running during rebase
- This is intentional to prevent rewriting historical commit messages
- The hook automatically detects and skips rebase operations
- Use `LLM_GITHOOK_FORCE=1` only if you specifically need to override this behavior

#### False positive in security scan
- Review the detected pattern in your code
- If legitimate, temporarily skip: `SKIP_SCAN_GITHOOK=1 git commit`
- Consider adjusting the pattern if it's a common false positive

#### Permission issues on Unix systems
```bash
# Ensure hooks are executable
chmod +x ~/.git-global-hooks/hooks/*
```

### Debug Mode
Enable verbose output for troubleshooting:
```bash
# For pre-commit hook
bash -x ~/.git-global-hooks/hooks/pre-commit

# For prepare-commit-msg hook
bash -x ~/.git-global-hooks/hooks/prepare-commit-msg
```

## 📋 Advanced Configuration

### Custom AI Prompts
The prepare-commit-msg hook uses a template system. You can customize the prompt:

```bash
# View current template
llm templates show commit-msg

# Create custom template
echo "Generate a commit message for these changes focusing on: $CHANGES" | \
     llm -s - --save commit-msg-custom
```

### Cache Management
Cached commit messages are stored in `~/.cache/git-llm-prepare-commit-msg/`:
- `last_md5`: MD5 hash of staged changes
- `last_message`: Cached commit message

**Smart Content Detection:**
- When staged changes are present, uses `git diff --staged` for message generation
- When no staged changes exist (e.g., `git commit --amend` message-only edits), automatically falls back to HEAD content
- Cache MD5 calculation adapts based on available content to ensure accurate cache hits

Clear cache:
```bash
rm -rf ~/.cache/git-llm-prepare-commit-msg/
```

### Hook Customization
To modify hook behavior, edit the files in `~/.git-global-hooks/hooks/`. Changes take effect immediately.

## 🤝 Contributing

Found a bug or have a feature request? Please open an issue or submit a pull request!

### Development Setup
```bash
# Clone for development
git clone https://github.com/tizee/git-hooks.git
cd git-hooks

# Test hooks locally
git config core.hooksPath ./hooks
```

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- [Simon Willison's llm](https://github.com/simonw/llm) for AI integration
- The git community for hook system inspiration
- Contributors and users who provide feedback and improvements
