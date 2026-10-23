# swaiz-extension-template

Template for a **swaiz extension** — an add-on that
`aictl` installs on top of the swaiz
platform. One extension per repository, built and released with
[`swaiz-extension-kit`](https://github.com/schaefersoft/swaiz-extension-kit).

The manifest here is the documented **reference** of everything an extension can
contribute (`apiVersion: aictl.io/v2`). Start from it and trim what you don't
need.

## Start a new extension

```sh
gh repo create schaefersoft/swaiz-<name> --private \
  --template schaefersoft/swaiz-extension-template --clone
cd swaiz-<name>
git switch -c dev && git push -u origin dev
```

Then:

1. In `extension.yaml` set `name:` (lowercase, dashes; it becomes the spec key,
   the download path and the tag prefix), `displayName:`, `description:` and
   `version:` (the first release ships it as-is). Trim everything else you don't
   need.
2. Delete the hooks and the n8n workflow unless you need them.
3. Write the user documentation in `.docs/` (see below).
4. Add a `check.sh` as soon as there is anything to test.
5. On the distribution server, link the extension to this repository and give
   the GitHub App access to it — the server pulls releases from there.

Work on `dev`, open pull requests against `release`. Every push to `release`
that changed the extension produces a release.

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
(cd dist && python3 -m http.server 8080) # serve the /dl tree like the real server
```

In a dev aictl install, set `license.serverURL: http://localhost:8080`, then
`aictl extension install <name>`. A locally built bundle is **unsigned**, so a
release `aictl` refuses it — local testing needs a `-tags dev` build.

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
