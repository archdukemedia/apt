# Arch-Duke Media apt repository

Install **Theatre**, **Herald** and **Merchant** with `apt`, and get every new version through your usual updates (`sudo apt upgrade` or the Software Updater).

Works on Zorin OS 18, Ubuntu 24.04 or newer, Linux Mint 22 or newer and Debian 13 or newer, on 64-bit PCs (amd64). Debian 12 is too old (its libadwaita is 1.2).

## Install

### The easy way: download and open

Download [theatre.deb](https://archdukemedia.github.io/apt/theatre.deb), [herald.deb](https://archdukemedia.github.io/apt/herald.deb) or [merchant.deb](https://archdukemedia.github.io/apt/merchant.deb) (always the newest version), open it, and click **Install** in the Software app. Installing it adds this repository, so new versions arrive with your usual updates. In a terminal (`sudo apt install ./theatre.deb`) it asks first, as VS Code's package does. Each app's `packaging/deb/` has the question and the scripts that add the repository; purging the last Arch-Duke Media app removes it again.

### Or add the repository yourself

Add the repository once:

```bash
sudo install -d -m 0755 /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/archdukemedia.gpg https://archdukemedia.github.io/apt/archdukemedia.gpg
sudo wget -qO /etc/apt/sources.list.d/archdukemedia.sources https://archdukemedia.github.io/apt/archdukemedia.sources
sudo apt update
```

Then install the apps you want:

```bash
sudo apt install theatre herald merchant
```

The signing key's fingerprint is `AB9E FDAD BAD8 571D FC20  DC82 457D E12A 62F3 AD84`. The key is trusted only for this repository (`Signed-By` in the `.sources` file), not for the rest of your system.

To remove the repository: `sudo rm /etc/apt/sources.list.d/archdukemedia.sources /etc/apt/keyrings/archdukemedia.gpg && sudo apt update`.

## How it works

- **Hosted on GitHub Pages** at https://archdukemedia.github.io/apt/. This git repository holds only the scripts, the workflow and the public key; no `.deb` is ever committed.
- **The apps' GitHub Releases are the source of truth.** The **Publish** workflow (`.github/workflows/publish.yml`) downloads the `.deb` of the newest 3 releases of each app (`scripts/fetch-debs.sh`), so people can go back a version with `sudo apt install theatre=<version>`; then it builds the repository with `apt-ftparchive` and signs it (`scripts/build-repo.sh`). Nothing is kept between runs, so there is no state to get out of step.
- **When it runs:** each app's Release workflow sends a `repository_dispatch` (`app-released`) after publishing a release; also on every push to main, by hand (*Actions → Publish → Run workflow*), and once a day as a safety net.
- **Checked on clean systems:** after publishing, the workflow follows the steps above word for word in fresh `ubuntu:24.04` and `debian:trixie` containers, installs all three apps, checks every program finds its libraries, and checks that an older Theatre upgrades with `apt upgrade` (`scripts/check-install.sh`).
- **One suite, `stable`.** The apps are built on Ubuntu 24.04 and each package lists the library versions it needs, so the same packages serve every supported system.

### Layout

```
archdukemedia.gpg, archdukemedia.asc      public signing key (binary and armored)
archdukemedia.sources                     the deb822 source file users download
volpesmedia.gpg, volpesmedia.asc,         the same key, and a source file pointing here, under
  volpesmedia.sources                     the names used before the rename to Arch-Duke Media
theatre.deb, herald.deb, merchant.deb     the newest version of each app, for download links
dists/stable/{InRelease,Release,Release.gpg}
dists/stable/main/binary-amd64/Packages{,.gz,.xz}
pool/main/<letter>/<package>/<package>_<version>_amd64.deb
```

## Secrets and access

| Where | Name | What |
|---|---|---|
| this repo | secret `APT_SIGNING_KEY` | the armored private signing key (no passphrase). Never committed; the owner keeps a backup |
| this repo and each app repo | variable `APT_APP_ID`, secret `APT_APP_PRIVATE_KEY` | the **Arch-Duke Media apt** GitHub App (Contents: read and write, installed on theatre, herald, merchant and apt). Each workflow asks for a short-lived token limited to what it needs: read the app repos here, write to this repo (to send the dispatch) in the apps |

Rotating the signing key: make a new key, replace `site/archdukemedia.gpg` and `site/archdukemedia.asc` (and their `volpesmedia.*` copies) and the `APT_SIGNING_KEY` secret together, and `packaging/deb/archdukemedia.gpg` in each app (their CI fails until it matches), and tell users to download the keyring again (the install step's second line). `scripts/build-repo.sh` signs only with the key whose public half is in `site/`, so a mismatched secret fails the build instead of publishing something users can't verify.

## Try it locally

```bash
GH_TOKEN=$(gh auth token) scripts/fetch-debs.sh /tmp/debs
UNSIGNED=1 scripts/build-repo.sh /tmp/debs /tmp/apt-site
```

## Contributing

Conventional Commits (`type(scope): description`), branches named `<type>/apt-<topic>`, never commit to main once the first version is in. See [AGENTS.md](AGENTS.md).
