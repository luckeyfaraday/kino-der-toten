# Contributing to Kino der Toten browser Zombies

Thanks for helping improve the project. By participating, you agree to follow
the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before opening a change

- Search existing issues and pull requests first.
- Open an issue before a large feature or architectural change.
- Do not submit proprietary assets, credentials, personal data, or material
  you do not have permission to redistribute.
- Keep pull requests focused and explain both what changed and why.

## Development

Use Node.js 24 and Git LFS, then install the locked dependencies:

```powershell
git lfs install
git lfs pull
npm ci
npm test
```

For gameplay or rendering work, follow [AGENTS.md](AGENTS.md). In particular,
run the browser checks for the map you changed and inspect their reports,
console output, and screenshots. Generated files under `artifacts/` are local
test evidence and must not be committed.

Before submitting a pull request, run `npm test` and the browser checks for
the affected map, for example:

```powershell
npm start                  # in a separate terminal; most browser checks use port 5173
npm run test:gameplay      # Kino
npm run test:moon          # Moon
npm run test:mobile        # touch controls; starts its own server
```

Describe any checks you could not run. Visual changes should include a current
screenshot; animation, timing, camera, and effects changes should include a
recording or trace when practical.

## Pull requests

Pull requests must:

- pass CI and the relevant browser/gameplay checks;
- avoid unrelated formatting or generated-file churn;
- document user-visible behavior changes;
- include tests for new behavior where practical; and
- confirm that submitted work may be distributed under the MIT license.

By contributing, you license your contribution under the repository's MIT
license. Third-party assets are excluded as described in
[ASSET_NOTICE.md](ASSET_NOTICE.md).
