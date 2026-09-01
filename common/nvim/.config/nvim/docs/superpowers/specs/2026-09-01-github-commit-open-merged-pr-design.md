# GitHub Commit Open Merged PR Design

## Goal

Make `:GithubCommitOpen` useful from `git blame` and commit-oriented buffers. Given the commit hash under the cursor, open that commit in the merged pull request that introduced it. Support both Meteorite and GitHub reviews without deriving review identity from local branches, worktree names, refs, or commit containment.

## Repository and commit resolution

Move the behavior into a focused `mmp.github_commit` module and keep the existing user command as a thin entry point.

Resolve repository coordinates from configured remotes in this order:

1. The `github` remote.
2. Another GitHub-hosted remote, preferring `upstream` and then `origin`.
3. A Gitstream remote when no GitHub-hosted remote exists.

This local metadata identifies the remote repository only. It must never determine which pull request owns the commit.

Accept a hexadecimal hash between 7 and 40 characters from the cursor. Resolve it to its canonical 40-character SHA through the remote commit API. For a Gitstream repository, prefer `gs api`; otherwise use `gh api`. Do not use local `git rev-parse` for canonicalization.

## Merged pull request discovery

Query every applicable remote review system using the canonical SHA.

### GitHub

Use GitHub's remote pull request search for the full SHA, limited to merged pull requests in the resolved repository. Treat search results as candidates rather than proof because a SHA can appear in pull request text.

Validate each candidate with remote pull request details. A GitHub candidate is valid only when the SHA is either:

- present in the pull request's remote commit list, or
- equal to its merge commit SHA.

### Meteorite

For a Gitstream repository, request `GET /repos/{owner}/{repo}/commits/{sha}/pulls` with pagination and retain merged candidates.

Gitstream's association endpoint includes broad historical snapshot and ancestry matches. Validate each candidate by requesting its remote commit list. A Meteorite candidate is valid only when the SHA is either:

- present in that pull request's remote commit list, or
- equal to its merge commit SHA.

This exact-membership check rejects unrelated pull requests whose snapshots merely contain the commit through base ancestry.

## Selection and navigation

Normalize valid candidates into a shared shape containing provider, number, title, merged timestamp, and URL. Deduplicate exact URL matches and sort by `merged_at`, oldest first, because the earliest merge is normally the review that introduced the change.

- One valid candidate: open it immediately.
- Multiple valid candidates: open a Telescope picker rather than guessing. Each row includes provider, pull request number, merge date, and title.
- Selection cancelled: do nothing.
- No valid candidates after every applicable lookup succeeds: open `https://github.com/{owner}/{repo}/commit/{full_sha}`.

Open a selected commit with its provider's contextual route:

- Meteorite: `https://meteorite.shopify.io/repos/{owner}/{repo}/pulls/{number}/commits/{sha}`
- GitHub: `https://github.com/{owner}/{repo}/pull/{number}/commits/{sha}`

Keep the current Google Chrome behavior for the final browser launch.

## Failure handling

Run remote commands asynchronously so Neovim remains responsive.

Report a concise notification and open nothing when:

- the cursor is not a plausible commit hash,
- no supported repository remote can be resolved,
- the hash cannot be resolved remotely, or
- an applicable review lookup or candidate validation fails.

A failed lookup is not equivalent to a confirmed absence. The repository commit fallback is allowed only after all applicable services return successfully with no valid merged pull request.

## Verification

Add a focused headless Lua spec with injected command, Telescope selection, browser, and notification adapters. Cover:

- Gitstream `origin` plus GitHub `github` resolves to `shop/world`, never a Gitstream browser URL.
- An abbreviated cursor hash is canonicalized remotely.
- Gitstream's broad association result is rejected when the exact commit is absent from that pull request.
- A valid Meteorite pull request opens its PR-scoped commit route.
- A valid GitHub pull request opens its PR-scoped commit route.
- A commit equal to a pull request's merge commit is accepted.
- Multiple valid merged pull requests open the selection window in oldest-merge-first order.
- Cancelling selection opens nothing.
- Confirmed absence opens the GitHub repository commit page.
- Invalid hashes, unresolved remotes, and API failures notify without opening a URL.

Run the new spec with primary Neovim in headless mode. Preserve the unrelated dirty changes in the original checkout by implementing and testing in the dedicated `miguelmora/github-commit-open-merged-pr` worktree.
