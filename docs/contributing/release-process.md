# Release Process

Maintainer checklist for cutting a release:

1. **Bump the version** — update `version` in `nimgeos.nimble`.
2. **Update the changelog** — add a `[X.Y.Z] - YYYY-MM-DD` heading to [CHANGELOG.md](https://github.com/JohnMoutafis/nimgeos/blob/main/CHANGELOG.md) with entries under the Keep-a-Changelog categories. Write it for users — features, guarantees, support, deferred items: this entry is also the source of the GitHub release notes (step 11).
3. **Check deprecations** — confirm any currently-deprecated API aliases still work, unless this release removes them per the [support policy](../support.md).
4. **Verify the metadata** — `nimble check` must report the package as valid, and `nimble dump --json` must show the expected `version`, `author`, `desc` and `license`. Nimble has no field for the repository link: the URL lives in the `nim-lang/packages` registry entry, which needs no update between releases.
5. **Verify a clean install** — the package must install and be importable outside the repository:

   ```sh
   TMP=$(mktemp -d)
   nimble install --nimbleDir:"$TMP" -y    # run from the package root, no package name:
   nimble path --nimbleDir:"$TMP" nimgeos  # nimble 0.22.x fails to resolve "install ."
   ```

   Then compile and run a small program that does `import nimgeos` against the directory `nimble path` printed. The installed directory must contain the flattened sources plus the `.nimble` file — not `tests/`, `docs/` or `site/`.
6. **Run the tests** — `nimble test` on a machine with GEOS installed (see the [installation guide](../getting-started/installation.md)).
7. **Build the documentation** — `nimble docs`, then regenerate the API reference and build the site the way CI does:

   ```sh
   nim doc --project --index:on --outdir:docs/api src/nimgeos.nim
   mkdocs build --strict
   ```

   `--strict` fails the build on broken links or nav entries missing from `mkdocs.yml`.
8. **Test the examples** — every fenced `nim` block in `README.md` and `docs/` that starts with an `import` line must compile and run, and its output must match the comments in the snippet.
9. **Verify CI** — green on Ubuntu and macOS with stable Nim (Windows and Nim-devel failures are informational).
10. **Tag** — create tag `vX.Y.Z` on `main` and push it.
11. **Publish the GitHub release** from the tag with notes taken from the changelog entry — publishing triggers the docs workflow, which rebuilds and deploys the documentation site including the API reference.
12. Nimble resolves releases from git tags — no separate registry publish step is needed.
