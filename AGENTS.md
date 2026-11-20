# Rules for AI agents working on the Volpes-Media apt repository

- **Never commit a private key, token or `.deb` file.** The signing key lives only in the `APT_SIGNING_KEY` secret and the owner's backup; packages come from the apps' GitHub Releases.
- **Never change `site/volpesmedia.gpg`** without the owner's yes: every user who added the repository would stop getting updates until they download the new key.
- **Commits**: Conventional Commits, `type(scope): description`, lower case, no full stop, with a body saying what changed and why. Branches: `<type>/apt-<topic>`, e.g. `ci/apt-keep-more-versions`. Never commit to `main`.
- **Docs match what's built**: change README.md (install steps, how it works, secrets) in the same pull request. If the install steps change, change them in each app's README too (theatre, tvcast, trader-bittorrent-client) and in `site/index.html`.
- Test locally with `UNSIGNED=1 scripts/build-repo.sh` (README, "Try it locally").
