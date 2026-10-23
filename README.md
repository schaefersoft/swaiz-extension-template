# swaiz-extension-template

Template for a **swaiz extension** — an add-on that
`aictl` installs on top of the swaiz
platform. One extension per repository, built and released with
[`swaiz-extension-kit`](https://github.com/schaefersoft/swaiz-extension-kit).

The manifest here is the documented **reference** of everything an extension can
contribute (`apiVersion: aictl.io/v2`). Start from it and trim what you don't
need.

The full workflow is in the developer handbook:
[Aufbau und Release](https://swaiz.ch/docs/entwickler/structure-and-release) and
[Lokal entwickeln](https://swaiz.ch/docs/entwickler/local-development).

## Start a new extension

Install the tools first — see
[Prerequisites](https://github.com/schaefersoft/swaiz-extension-kit#prerequisites)
in the kit.

### 1. Create the repository

```sh
gh repo create schaefersoft/swaiz-<name> --private \
  --template schaefersoft/swaiz-extension-template --clone
cd swaiz-<name>
git switch -c dev && git push -u origin dev
```

`release` is the default branch; every push to it that changed the extension
produces a release. Work happens on `dev`.

### 2. Make it yours

1. In `extension.yaml` set `name:` (lowercase, dashes; it becomes the spec key,
   the download path and the tag prefix), `displayName:`, `description:` and
   `version:` (the first release ships it as-is). Trim everything else you don't
   need.
2. Delete the hooks and the n8n workflow unless you need them.
3. Write the user documentation in `.docs/` (see below).
4. Add a `check.sh` as soon as there is anything to test.
5. Add the `composer`, `npm`, `gomod` or `docker` ecosystems for your
   `services/` directories to `.github/dependabot.yml`.

### 3. Repository settings

GitHub copies files from a template, not settings. Set them once:

- **General:** turn off the wiki, turn on *Automatically delete head branches*.
- **Rulesets** (public repositories; private ones need a paid plan): protect
  `release` and `dev` against deletion and force pushes.

  ```sh
  for b in release dev; do
    gh api -X POST repos/schaefersoft/swaiz-<name>/rulesets --input - <<JSON
  {"name":"$b","target":"branch","enforcement":"active",
   "conditions":{"ref_name":{"include":["refs/heads/$b"],"exclude":[]}},
   "rules":[{"type":"deletion"},{"type":"non_fast_forward"}]}
  JSON
  done
  ```

  Do **not** require pull requests or status checks on `release`: the release
  workflow pushes its version bump there directly and would be rejected.
- **Security:** Dependabot alerts on
  (`gh api -X PUT repos/schaefersoft/swaiz-<name>/vulnerability-alerts`); for a
  public repository also secret scanning and push protection (*Settings → Code
  security*).

### 4. Register it with the distribution server

The server only pulls releases from repositories it knows. Create the extension
in the customer portal under *Erweiterungen* and link it to this repository
through your company's GitHub connection, see
[Aufbau und Release](https://swaiz.ch/docs/entwickler/structure-and-release#release-ablauf).

### 5. Release

Merge `dev` into `release`. The release workflow lints the manifest, runs
`check.sh`, builds the bundle and images, commits the version bump to
`release`, tags `<name>/v<version>` and publishes a GitHub Release. The
distribution server picks it up within about a minute and signs it; from then
on `aictl extension install <name>` works for licenses entitled to the
extension.

The version bump lands on `release` only. `version:` on `dev` therefore stays
behind — the released version is the newest `<name>/v*` tag
(`git tag -l '<name>/v*' --sort=-v:refname | head -1`). After the first release,
never change `version:` by hand; the commits decide.

## What's inside

| Path | Purpose |
|---|---|
| `extension.yaml` | the full `aictl.io/v2` surface: identity, `platform` gate, `deprecated`, `requires.disk`, models with `type`, databases with Postgres `extensions`, typed secrets, **services** with the `needs` map plus `health`, routes, `toolServer`, `resources.gpu`, `stopGracePeriod` and `${version}` image refs, **jobs**, named **hooks**, the **state** section and n8n workflows |
| `hooks/post-install.sh` | a postInstall escape-hatch example (most extensions ship **no** hooks) |
| `hooks/pre-uninstall.sh` | a preUninstall escape-hatch example |
| `n8n/example-workflow.json` | a minimal, valid, importable workflow (stable `id`) |
| `.docs/` | user documentation, synced by the distribution server from each release tag |
| `services/<svc>/Dockerfile` | (add when needed) the extension's own service images |
| `check.sh` | (add when needed) the extension's own checks; CI and every release run it |
| `.github/workflows/` | `ci` lints and checks pull requests, `release` ships pushes to `release` — both from the kit |

The database **schema is not a manifest concern** in v2: the application owns
it and runs it from a `preStart` job or its entrypoint.

Secrets never carry values in the bundle. `required`/`optional` ones are
supplied by the operator with `aictl secret set <NAME>`; `generated` ones are
invented by aictl and injected under their declared name into exactly the
services that list them in `envSecrets`.

## Documentation

Chapters live in `.docs/` as `NN_<slug>.md` (`01_overview.md`,
`02_setup.md`, …), written in German for the customer's administrators. The
distribution server reads them from the release tag, so documentation changes
ship with a release like code.

## Build & test locally

```sh
export PATH="$HOME/swaiz-extension-kit/bin:$PATH"   # a clone of the kit

aictl extension lint .                   # manifest validation, offline
bash check.sh                            # the extension's own checks
swaiz-ext-build-images .                 # own service images → images/
swaiz-ext-build .                        # → dist/dl/extensions/<name>/<version>/
```

A locally built bundle is **unsigned**, and every `aictl` refuses it, dev builds
included. The real install flow is tested with a server-signed pre-release on a
test installation, see
[Lokal entwickeln](https://swaiz.ch/docs/entwickler/local-development#testrelease-auf-einer-testinstallation).

## Rules that matter

- **`version:` is semver**; the release workflow bumps it automatically from
  the Conventional Commit subjects (`feat:` → minor, `fix:` → patch, `type!:` →
  major).
- **Declare, don't script.** If aictl can converge it from data (models, DBs,
  secrets, services, routing, state, n8n), use a manifest field; in-container
  work is a **job**; reach for a **hook** only for the genuinely imperative on
  the host itself.
- **A service reaches only what its `needs` declare.** The baseline network
  carries postgres, litellm and traefik; qdrant/n8n/searxng have no network
  path without the need — and no need means no injected credential either.
- **Service images:** an extension's **own** image (built from a
  `services/<svc>/Dockerfile`) ships **inside the bundle** as a `docker save`
  tarball — `swaiz-ext-build-images` builds it as `<name>-<svc>:<version>`,
  `swaiz-ext-build` folds it in, and aictl `docker load`s it at install
  (integrity from the signed checksums, no registry digest). Reference it as
  `<name>-<svc>:${version}` so a release never has to retag the manifest. A
  **third-party** image is pulled from its registry at install — pin it by
  digest. Extensions never bind host ports — ingress is via a `route:` through
  Traefik.
- **Workflows publish on install/update** when `publish: true`; otherwise they
  import unpublished and you enable them in the n8n UI.
- **Dependabot** watches the GitHub Actions only. Add the `composer`, `npm`,
  `gomod` or `docker` ecosystems for your `services/` directories in
  `.github/dependabot.yml` once they exist.

## License

MIT-0 — see [LICENSE](LICENSE). Use the template for your own extension, open
or proprietary, without carrying a notice along.
