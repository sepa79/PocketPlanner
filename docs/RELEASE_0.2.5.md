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

The new tag v0.2.5 matches VERSION. Existing tags are not changed. The tag workflow
validates, builds and publishes linux/amd64 and linux/arm64, then uses the emitted
immutable registry digest to run scripts/smoke-image.sh for each platform.
The arm64 runtime smoke uses QEMU on the amd64 runner; it is not a native ARM
hardware/performance test. Both smokes verify /health, /api/info version 0.2.5 and
SQLite-backed empty seed state. All writes stay in fresh tmpfs mounts; exact owned
containers are removed on exit, with no named volume or working service changes.

Publication is complete only after the whole tag workflow succeeds and a separate
registry check verifies the index digest, both platform manifests, source revision
and version labels, plus equality of the source-commit and release tags. A pushed
tag or successful dispatch alone is not proof. No deployment is included.
