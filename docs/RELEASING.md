# Release process

## Version policy

The project uses semantic versioning:

- Patch: compatible fixes and documentation corrections.
- Minor: compatible features, new optional services, or new commands.
- Major: breaking configuration, directory, backup format, command behavior, or security-model changes.

The canonical version is stored in `VERSION` and must match the changelog heading and Git tag.

## Release checklist

1. Review all staged changes and confirm there are no unrelated refactors.
2. Update `VERSION` and move changelog entries from `Unreleased` to a dated release heading.
3. Review every upstream image tag, digest, source revision, and license.
4. Run `AI_GATEWAY_IMAGE_SCAN=1 ./tests/scan-images.sh`; update `docs/SECURITY_BASELINE.md` and review every exception rather than increasing the threshold silently.
5. Run `./tests/validate.sh` and ShellCheck.
6. Run `AI_GATEWAY_SMOKE=1 ./tests/smoke.sh` on Linux with a reachable Docker daemon.
7. Verify a backup created by the previous release can be restored by the target release, or document a migration.
8. Confirm `git diff --check`, the built-in secret scan, and Gitleaks pass.
9. Commit with a public or GitHub noreply author email.
10. Create a signed annotated tag such as `v0.1.0`.
11. Publish release notes containing impact, migration, rollback, verified tests, and known limitations.
12. Enable GitHub private vulnerability reporting and Discussions.
13. Protect the default branch with required CI and review rules appropriate to the maintainer model.
14. Verify GitHub's community profile recognizes README, LICENSE, SECURITY, SUPPORT, CONTRIBUTING, and CODE_OF_CONDUCT.

## Release artifacts

The Git repository is the release artifact. Do not upload runtime directories, `.env`, databases, logs, backups, certificates, or a working production directory as a source archive.

GitHub-generated source archives are acceptable after the tag has passed CI. Container images remain external third-party artifacts and are identified by digest in `.env.example` and `docs/UPSTREAM.md`.
