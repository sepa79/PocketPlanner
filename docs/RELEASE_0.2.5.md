# PocketPlanner 0.2.5 verification

Date: 2026-11-03. Includes the dedicated MCP test executor and four-CPU CI gate
from [0.2.4](RELEASE_0.2.4.md). No runtime authorization or planning semantics change.

## Additional publication blocker

The [0.2.4 run](https://github.com/sepa79/PocketPlanner/actions/runs/41705402462)
passes validate, including 219 UI and 621 Java tests. Publication then fails
because the Docker frontend stage runs under QEMU for arm64: nine UI tests
exceed their unchanged 5000 ms deadlines. The amd64 Java Docker build passes.
No complete multi-platform 0.2.4 image is published by that failed run.

React static assets and Java bytecode are architecture-independent. Their Docker
build/test stages now explicitly use BUILDPLATFORM; no tests or timeouts are
disabled or relaxed. The final JRE stage still uses each requested TARGETPLATFORM.
SQLite JDBC contains both Linux x86_64 and aarch64 native libraries; those remain
bundled, not cross-compiled or replaced by a host-only dependency.

## Gates

Local source tests with JAVA_TOOL_OPTIONS=-XX:ActiveProcessorCount=4 pass all
219 UI and 621 Java cases. All 14 deployment-rendering checks and the native
Docker build pass; the amd64 image smoke confirms version 0.2.5 and healthy
SQLite with an empty tmpfs workspace, and removes its own container afterwards.
Evidence is retained under /tmp/pp-release-0.2.5-20261103/.
The 0.2.4 report retains the original before/after
four-CPU reproduction and the failure links; it is not evidence of publication.

The tag v0.2.5 matches VERSION. Existing tags are not changed. During the initial
multi-platform attempt the operator selected **linux/amd64 only**. The owned
obsolete run was cancelled, but publication completed before cancellation took
effect: v0.2.5 already points to a two-platform index at
sha256:60960e1716021dcafb281bd2f991137dbe9d0edb7e289b5f1a3cc2c87512124d.
That historical image/source tag is not overwritten or removed. No new version
is needed: manually run the current workflow on main with release_tag set to
v0.2.5 to publish the distinct v0.2.5-amd64 image. Both jobs check out refs/tags/v0.2.5;
the source revision is that tag's commit, not the newer workflow commit. Version
and source-image tags/labels are derived from that actual checkout.

The workflow publishes linux/amd64 only, without QEMU or ARM smoke steps. Source
image tags are sha-<source-revision>-amd64. Normal future release-tag pushes
publish both vX.Y.Z and vX.Y.Z-amd64; explicit manual builds publish only the
architecture-suffixed release tag, never replacing a historical base release.
The workflow
uses the emitted immutable digest to run scripts/smoke-image.sh for amd64.
The smoke verifies /health, /api/info version 0.2.5 and
SQLite-backed empty seed state. All writes stay in fresh tmpfs mounts; exact owned
containers are removed on exit, with no named volume or working service changes.

Publication is complete only after the whole workflow succeeds and a separate
registry check verifies the digest, sole amd64 runtime manifest, source revision
and version labels, plus equality of the source-commit and release tags. A pushed
tag or successful dispatch alone is not proof. No deployment is included.
