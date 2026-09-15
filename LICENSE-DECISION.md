# License decision

English | [Italiano](LICENSE-DECISION.it.md)

**Decision date:** 2026-09-15
**Scope:** The Switcher source code, PowerShell and Unix wrappers, installation scripts,
tests, templates, and repository documentation.
**License:** MIT (`MIT` SPDX identifier)

## Rationale

The rights holder selected MIT to support broad use, modification,
redistribution, and commercial adoption of this cross-platform developer tool. MIT is
an established permissive software license and is appropriate for this code
and its accompanying technical documentation.

## Boundaries and inputs

- The repository contains no vendored third-party source, datasets, model
  weights, or media as of this decision.
- Dependencies invoked by users or CI (Codex CLI, `ccusage`, Python, Pester,
  PSScriptAnalyzer and ShellCheck) retain their own licenses and are not bundled here.
- `mr-jonam` is a public pseudonymous owner reference used for repository
  attribution; no personal identity, private key, API key, or recovery secret
  is stored in the repository.
- The GitHub repository is intended for public distribution. GitHub's Terms
  can permit viewing and platform forking; MIT separately grants the stated
  reuse rights.

## Alternatives considered

Apache-2.0 and MPL-2.0 were considered. The user selected MIT because the
project does not require a patent clause or file-level reciprocity.

## Evidence limits

The provenance manifest records a content hash and a random project identifier
for integrity and correlation only. It is not DRM, guaranteed tracing, or
conclusive legal proof of ownership. Seek legal advice and qualified timestamp
services where stronger evidence is required.
