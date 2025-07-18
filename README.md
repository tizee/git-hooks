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
- **Safety Features**: Skip modes for amending commits and merge operations

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
- `SKIP_LLM_GITHOOK=1`: Skip AI commit message generation
- `FORCE_LLM_GITHOOK=1`: Force regeneration even with unchanged diffs
- `NO_BYPASS_AMENDING=1`: Prevent bypass during commit amending
- `GITHOOK_SPINNER=dots`: Set spinner style (see available styles below)

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
SKIP_LLM_GITHOOK=1 git commit

# Bypass for amending
git commit --amend
```

### Force Regeneration
```bash
# Regenerate even if changes are cached
FORCE_LLM_GITHOOK=1 git commit --amend
```

### Custom Spinner Style
```bash
# Use dots spinner
GITHOOK_SPINNER=dots git commit

# Set permanently in your shell profile
echo 'export GITHOOK_SPINNER=dots' >> ~/.zshrc
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
- Skip AI generation: `SKIP_LLM_GITHOOK=1 git commit`

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