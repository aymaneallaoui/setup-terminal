# Universal Terminal Setup 🚀

![Terminal Preview](image-6.png)

A **one-run script** that automatically sets up a beautiful and powerful terminal environment for both **Windows PowerShell** and **Linux/WSL**!

## ✨ What's New

- 🎯 **One-click setup** - No more 5 manual steps!
- 🔄 **Cross-platform** - Works on Windows, Linux, WSL, and macOS
- 🤖 **Smart detection** - Automatically detects your environment
- ⚡ **Modern tools** - Uses the latest terminal enhancements

## 🚀 Quick Start

### One-Line Installation

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/aymaneallaoui/setup-terminal/master/setup.sh | bash
```

Or download and run manually:

```bash
# Clone the repository
git clone https://github.com/aymaneallaoui/setup-terminal.git
cd setup-terminal

# Make the script executable and run it
chmod +x setup.sh
./setup.sh
```

### Windows PowerShell Alternative

If you're on Windows and prefer PowerShell:

```powershell
# Run directly in PowerShell
iwr -useb https://raw.githubusercontent.com/aymaneallaoui/setup-terminal/master/setup.ps1 | iex
```

## 🎨 Features

### 🖼️ Beautiful Terminal Icons
![Terminal Icons](image-1.png)

### 📜 Enhanced Command History
![Command History](image-2.png)

### 🔍 Fuzzy File Finder
Use `Ctrl + F` to search for files and `Ctrl + R` to search command history
![File Finder](image-3.png)

### 🔧 Improved Git Experience
![Git Integration](image-4.png)

Git commands auto-completion: `git ch` + `Tab` → `git checkout`

### ⚡ PowerShell Auto-Completion
![PowerShell Completion](image-5.png)

PowerShell commands auto-completion: `Get-` + `Tab` → `Get-Command`

## 🛠️ What Gets Installed

### For Linux/WSL:
- **fzf** - Fuzzy finder for files and command history
- **Starship** - Beautiful, fast prompt
- **Zsh + Oh My Zsh** (if Zsh is available)
- **Zsh plugins**:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - powerlevel10k theme
- **Git integration** with helpful aliases
- **Enhanced Bash** configuration (if Zsh not available)

### For Windows PowerShell:
- **Oh My Posh** - Beautiful prompt system
- **Scoop** - Package manager for Windows
- **PowerShell modules**:
  - PSReadLine - Enhanced command line editing
  - Terminal-Icons - File and folder icons
  - Posh-Git - Git integration
  - PSFzf - Fuzzy finder integration
- **fzf** - File and history search
- **Git aliases** and auto-completion

## 🎛️ Key Bindings

| Shortcut | Function |
|----------|----------|
| `Ctrl + R` | Search command history |
| `Ctrl + F` | Find files |
| `Tab` | Auto-complete commands/paths |
| `↑/↓` | Navigate command history |

## 📋 Git Aliases

The setup includes these helpful git aliases:

```bash
gs    # git status
ga    # git add
gc    # git commit
gp    # git push
gl    # git log --oneline
gd    # git diff
gb    # git branch
gco   # git checkout
```

## 🔧 Customization

### Changing Themes

**For Zsh (Linux/WSL):**
```bash
# Edit ~/.zshrc and change the theme line
ZSH_THEME="powerlevel10k/powerlevel10k"
```

**For PowerShell:**
```powershell
# Edit your PowerShell profile and change the Oh My Posh theme
oh-my-posh init pwsh --config "path/to/your/theme.omp.json" | Invoke-Expression
```

### Adding Custom Aliases

**Linux/WSL:**
Add to `~/.zshrc` or `~/.bashrc`:
```bash
alias myalias='my command'
```

**PowerShell:**
Add to your PowerShell profile:
```powershell
Set-Alias myalias 'My-Command'
```

## 🐛 Troubleshooting

### Script Won't Run
Make sure the script is executable:
```bash
chmod +x setup.sh
```

### PowerShell Execution Policy Error
Run this in PowerShell as Administrator:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Missing Dependencies
The script automatically installs dependencies, but if you encounter issues:

**Linux/WSL:**
```bash
sudo apt update && sudo apt install curl git build-essential
```

**Windows:**
Install Git and PowerShell from their official websites.

### WSL Specific Issues
If you're using WSL and encounter font issues, install a Nerd Font in Windows Terminal:
1. Download a Nerd Font (e.g., FiraCode Nerd Font)
2. Install it in Windows
3. Set it as the font in Windows Terminal settings

## 🆕 Migration from Old Setup

If you were using the old 5-step process:

1. **Backup your current config** (optional):
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp $PROFILE $PROFILE.backup  # PowerShell
   ```

2. **Run the new setup**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/aymaneallaoui/setup-terminal/master/setup.sh | bash
   ```

3. **Restart your terminal**

The new setup will automatically detect and preserve compatible configurations.

## 🤝 Contributing

Want to improve this setup? Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test on different environments
5. Submit a pull request

### Adding Support for New Shells/OS
The script is designed to be extensible. To add support for a new environment:

1. Add detection logic in `detect_environment()`
2. Create a new setup function (e.g., `setup_fish()`)
3. Add the case in the main function
4. Test thoroughly

## 📜 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Original setup by [aymaneallaoui](https://github.com/aymaneallaoui)
- Enhanced with cross-platform support
- Thanks to the maintainers of:
  - [Oh My Posh](https://ohmyposh.dev/)
  - [Oh My Zsh](https://ohmyz.sh/)
  - [Starship](https://starship.rs/)
  - [fzf](https://github.com/junegunn/fzf)
  - All the PowerShell and Zsh plugin authors

---

## 🎉 Enjoy Your Enhanced Terminal!

After installation, restart your terminal and enjoy:
- ⚡ Faster workflow with fuzzy finding
- 🎨 Beautiful, informative prompts
- 🔧 Powerful git integration
- 📝 Enhanced command editing
- 🚀 Cross-platform consistency

**Star this repo if it helped you! ⭐**