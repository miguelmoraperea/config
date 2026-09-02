# GitHub Commit Open Merged PR Design

## Goal

Make `:GithubCommitOpen` useful from `git blame` and commit-oriented buffers. Given the commit hash under the cursor, open that commit in the merged pull request that introduced it. Support both Meteorite and GitHub reviews without deriving review identity from local branches, worktree names, refs, or commit containment.

## Repository and commit resolution

Move the behavior into a focused `mmp.github_commit` module and keep the existing user command as a thin entry point.

Discover GitHub and Gitstream repository identities independently from configured remotes:

- For GitHub, prefer the `github` remote, then another GitHub-hosted remote named `upstream` or `origin`, then any remaining GitHub-hosted remote.
- For Gitstream, use a Gitstream-hosted remote whenever one exists, regardless of which remote supplied the GitHub identity.

A checkout such as `shop/world`, with Gitstream `origin` and GitHub `github`, therefore enables both review lookups. Each provider receives the `owner/repo` coordinates parsed from its own remote. If only a Gitstream remote exists, its coordinates also supply the GitHub repository commit fallback because Gitstream mirrors the GitHub repository namespace.

This local metadata identifies remote repositories only. It must never determine which pull request owns the commit.

Accept a hexadecimal hash between 7 and 40 characters from the cursor. Resolve it to its canonical 40-character SHA through the remote commit API. Prefer `gs api` when a Gitstream identity exists, with `gh api` as the GitHub-only path. Do not use local `git rev-parse` for canonicalization.

## Merged pull request discovery

Query every applicable remote review system using the canonical SHA.

### GitHub

Use `gh search prs {sha} --repo {owner}/{repo} --merged` for the full SHA. Treat search results as candidates rather than proof because a SHA can appear in pull request text.

Validate each candidate with remote pull request details and its paginated REST commit list. A GitHub candidate is valid only when the SHA is either:

- present in the pull request's remote commit list, or
- equal to its merge commit SHA.

### Meteorite

Whenever a Gitstream identity exists, request `GET /repos/{owner}/{repo}/commits/{sha}/pulls` with `gs api --paginate` and retain only candidates whose `merged` field is true.

Gitstream's association endpoint includes broad historical snapshot and ancestry matches. Validate each candidate by requesting its remote commit list. A Meteorite candidate is valid only when the SHA is either:

- present in that pull request's remote commit list, or
- equal to its merge commit SHA.

This exact-membership check rejects unrelated pull requests whose snapshots merely contain the commit through base ancestry.

## Verified remote contracts

The following authenticated calls were verified against `shop/world` on 2026-09-01:

- `gs api repos/shop/world/commits/{sha}/pulls?per_page=100 --paginate` returns one combined JSON array. Candidate fields are `number`, `merged`, `merged_at`, `merge_commit_sha`, and `title`.
- `gs api repos/shop/world/pulls/{number}/commits?per_page=100 --paginate` returns commit objects whose canonical hash is in `sha`.
- `gh search prs {sha} --repo shop/world --merged --json number,title,state,closedAt,url` returned merged GitHub PR `1006544` for `5ef9def9bb4c7212edfa90db368b255db4d686d0`.
- `gh api repos/shop/world/pulls/1006544` returned `merged`, `merged_at`, `merge_commit_sha`, `number`, `title`, and `html_url`.
- `gh api --paginate repos/shop/world/pulls/1006544/commits?per_page=100` returned member hashes as `sha` on each paginated commit object.

For the same commit, Gitstream returned many later snapshot associations that did not include PR `1006544`. Exact remote commit-list validation is therefore required rather than relying on association ordering.

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

- Gitstream `origin` plus GitHub `github` enables both provider lookups for `shop/world`, never a Gitstream browser URL.
- An abbreviated cursor hash is canonicalized remotely.
- Gitstream's broad association result is rejected when the exact commit is absent from that pull request.
- An open association is excluded even when its remote commit list contains the SHA.
- With both remotes configured, GitHub's true merged PR wins when Gitstream returns only unrelated or open associations for the same SHA.
- A valid Meteorite pull request opens its PR-scoped commit route.
- A valid GitHub pull request opens its PR-scoped commit route.
- A commit equal to a pull request's merge commit is accepted.
- Multiple valid merged pull requests open the selection window in oldest-merge-first order.
- Cancelling selection opens nothing.
- Confirmed absence opens the GitHub repository commit page.
- Invalid hashes, unresolved remotes, and API failures notify without opening a URL.

Run the new spec with primary Neovim in headless mode. Preserve the unrelated dirty changes in the original checkout by implementing and testing in the dedicated `miguelmora/github-commit-open-merged-pr` worktree.
