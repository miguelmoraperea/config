# PR GitSigns - Enhanced Git Diff Workflow

This module enhances your PR review workflow by automatically configuring gitsigns to show changes relative to the base branch when you're working on a PR branch.

## How It Works

When you're on a PR branch (any branch that's not main/master), the module can automatically configure gitsigns to compare against the merge base with the main branch instead of just HEAD. This gives you persistent visual indicators of what changed in your PR while you navigate the code.

## Usage

### Automatic Mode
- When you close diffview (using `:DiffviewClose` or `<Leader>do`), the system automatically enables PR diff mode if you're on a PR branch
- When you switch to a PR branch, it automatically enables PR diff mode
- When you switch back to main/master, it automatically disables PR diff mode

### Manual Commands
- `:PRDiffToggle` or `<Leader>pd` - Toggle PR diff mode on/off
- `:PRDiffStatus` or `<Leader>ps` - Show current status
- `:PRDiffEnable` - Manually enable PR diff mode
- `:PRDiffDisable` - Manually disable PR diff mode

### Workflow Example

1. Use `:TeamPR` to open a PR with diffview
2. Review changes in diffview
3. Close diffview with `<Leader>do` or `:DiffviewClose`
4. **Automatically**, gitsigns will now show changes relative to the base branch
5. Navigate through your code and see persistent git signs showing PR changes
6. Use `{c` and `(c` to navigate between changed hunks
7. Use other gitsigns commands like `<leader>hp` to preview hunks

### Visual Indicators

When PR diff mode is enabled, you'll see:
- Git signs in the sign column showing lines that changed in your PR
- Line highlighting (if enabled) for changed lines
- All the normal gitsigns functionality but comparing against the merge base

### Status Information

Use `<Leader>ps` or `:PRDiffStatus` to see:
- Current branch name
- Whether you're on a PR branch
- Whether PR diff mode is enabled
- What commit you're comparing against

## Configuration

The module is automatically loaded and configured. No additional setup is required.

## Keybindings

- `<Leader>pd` - Toggle PR diff mode
- `<Leader>ps` - Show PR diff status
- `<Leader>do` - Close diffview (will auto-enable PR diff mode)

## Technical Details

- Detects PR branches as any branch that's not main/master
- Uses `git merge-base` to find the common ancestor with the main branch
- Integrates with gitsigns' `change_base` functionality
- Automatically handles branch switching and diffview integration
