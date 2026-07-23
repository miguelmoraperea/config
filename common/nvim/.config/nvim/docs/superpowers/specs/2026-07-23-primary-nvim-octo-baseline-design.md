# Primary Neovim Octo Baseline Design

## Goal

Add a small, usable Octo configuration to Miguel's primary Neovim setup so Octo can be evaluated alongside the existing TeamPR, Diffview, and Gitsigns workflows.

## Scope

Create a dedicated Lazy plugin specification for `pwntester/octo.nvim`. Keep the existing PR review tools unchanged and give Octo its own `<leader>o` key group.

The baseline will use:

- Telescope as the picker.
- GitHub-hosted review files (`use_local_fs = false`), avoiding automatic local branch checkout for reviews.
- Remote preference `github`, then `upstream`, then `origin`, so World API operations avoid the Gitstream remote when Octo resolves the repository.
- Octo's built-in action picker.

## Plugin specification

Add `lua/plugins/octo.lua` with:

- Lazy loading through the `:Octo` command and Octo key mappings.
- Direct dependencies on Plenary, Telescope, and Web Devicons.
- Mostly stock Octo settings, retaining only the options already validated in the disposable profile.

Mappings:

- `<leader>oo`: open Octo's action picker.
- `<leader>op`: list pull requests for the current repository.
- `<leader>oi`: list issues for the current repository.
- `<leader>on`: list notifications.
- `<leader>os`: search the current repository.
- `<leader>or`: run `:Octo review browse`, which browses the current PR review without starting a pending review.

Explicit PR navigation remains available through `:Octo NUMBER OWNER/REPO` or a GitHub PR URL.

## Coexistence

Do not change TeamPR commands, Diffview configuration, Gitsigns configuration, or their existing mappings. Octo is additive and independently removable.

## Known baseline limitations

- Listing every open PR in `shop/world` is slow because Octo paginates the entire repository result set.
- Current-branch fallback uses bare `gh pr view`; a branch tracking Gitstream can therefore report that no PR exists. Opening a PR explicitly avoids this.
- Octo's checkout action invokes `gh pr checkout`, which Gitstream blocks. Remote review browsing does not require checkout.

These limitations remain visible in the baseline so subsequent changes can be evaluated independently.

## Verification

Add `tests/octo_spec.lua`, executed with primary Neovim in headless mode using `+luafile tests/octo_spec.lua`, to verify:

- The plugin is registered and loadable.
- The selected options are applied.
- All six mappings resolve to their named Octo actions.
- Existing TeamPR commands still exist.

After Octo loads, run `:checkhealth octo` headlessly, read the generated health buffer, and assert that the Octo report contains no `ERROR` entries. The existing authenticated `gh` session should pass authentication; the test must not inject or persist credentials.

Install only Octo and update its `lazy-lock.json` entry without updating unrelated plugins. Before and after verification, compare the existing dirty working tree so unrelated in-progress Neovim and tmux changes remain untouched.
