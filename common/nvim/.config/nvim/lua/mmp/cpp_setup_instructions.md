# C++ Development Setup for Neovim

This document outlines the C++ development configuration for your reportify-cpp project.

## What's Been Configured

### 1. Language Server Protocol (LSP)
- **clangd** configured with optimal settings for C++20 development
- Background indexing enabled for fast navigation
- clang-tidy integration for static analysis
- Smart header insertion and completion
- Configured to use `build/compile_commands.json` for project-specific settings

### 2. Project-Specific Settings
- Auto-formatting on save (only for reportify-cpp project files)
- C++ specific indentation and formatting
- Text width set to 100 characters to match project standards
- C++20 standard with proper syntax highlighting

### 3. Build System Integration
- CMake integration with compile_commands.json generation
- Custom commands for common development tasks:
  - `:CppBuild [Debug|Release]` - Build the project
  - `:CppConfigure [Debug|Release]` - Configure CMake
  - `:CppTest` - Run tests
  - `:CppRun [args]` - Run the executable
  - `:CppFormat` - Format all source files
  - `:CppLint` - Run static analysis
  - `:CppClean` - Clean build directory

### 4. Key Mappings (Active only in reportify-cpp files)
- `<leader>cb` - Build project
- `<leader>cr` - Run executable
- `<leader>ct` - Run tests
- `<leader>cc` - Configure project
- `<leader>cf` - Format code
- `<leader>cl` - Lint code
- `gh` - Switch between header/source files
- `go` - Alternative switch command (already in your config)

### 5. Tree-sitter Support
- C and C++ parsers already configured for syntax highlighting
- Enables better code understanding and folding

### 6. Mason Integration
- clangd and clang-format will be auto-installed via Mason
- Run `:MasonInstall clangd clang-format` if not auto-installed

## Project Structure Recognition

The configuration automatically detects when you're working on the reportify-cpp project by checking if the file path contains "reportify-cpp". This ensures the C++ settings only apply to your specific project.

## Files Created/Modified

1. `/Users/miguel/Desktop/git/config/common/nvim/.config/nvim/lua/mmp/cpp.lua` - Main C++ configuration
2. `/Users/miguel/Desktop/git/config/common/nvim/.config/nvim/lua/mmp/lsp.lua` - Added clangd LSP setup
3. `/Users/miguel/Desktop/git/config/common/nvim/.config/nvim/lua/mmp/init.lua` - Added C++ setup call
4. `/Users/miguel/Desktop/git/config/common/nvim/.config/nvim/lua/plugins/core.lua` - Added Mason packages
5. `/Users/miguel/src/github.com/Shopify/merchant-analytics-etl/reportify-next/reportify-cpp/.clangd` - clangd configuration

## Next Steps

1. Restart Neovim or run `:so $MYVIMRC` to load the new configuration
2. Open a C++ file in your reportify-cpp project
3. The LSP should automatically start and begin indexing
4. Use `:LspInfo` to verify clangd is running
5. Try the new commands and keybindings

## Troubleshooting

- If clangd doesn't start, ensure it's installed: `:MasonInstall clangd`
- If completion isn't working, check that `compile_commands.json` exists in the build directory
- If formatting doesn't work, install clang-format: `:MasonInstall clang-format`
- Use `:LspLog` to check for any LSP errors

## Customization

You can modify the settings in `lua/mmp/cpp.lua` to adjust:
- Compiler flags and options
- Code formatting style
- Build commands and paths
- Key mappings

The configuration is designed to be project-specific, so it won't interfere with other C++ projects you might work on.
