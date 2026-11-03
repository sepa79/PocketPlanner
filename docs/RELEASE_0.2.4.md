# PocketPlanner 0.2.4 verification

Date: 2026-11-03. Test/CI patch; no runtime, authorization, database or UI behavior
change. Existing services and operational data are not restarted or replaced.

## Cause and correction

The failed [0.2.3 tag run](https://github.com/sepa79/PocketPlanner/actions/runs/39973338325)
and [latest pre-fix main run](https://github.com/sepa79/PocketPlanner/actions/runs/39980675115)
both stopped in McpHttpTest.concurrentClientsCannotBorrowIdentityAndPublicReadsNeedNoVerifiedIdentity:
AUTH_503, one Java test error, publish skipped. Their frontend/deployment checks
passed. This was the test's synthetic identity service, not the deployed PH.

The unchanged test reproduces FAIL at four visible CPUs and PASS at sixteen.
A thread dump shows the common ForkJoinPool occupied by blocking SDK calls while
identity requests wait. The fix uses a test-owned virtual-thread executor with
scoped cleanup. All 18 calls, identity request counts, anonymous/public behavior
and revocation checks remain. No retries, disabled tests, extended timeouts or
production authorization changes are introduced.

## Local validation

- The focused concurrency regression passes with -XX:ActiveProcessorCount=4.
- The full build with JAVA_TOOL_OPTIONS=-XX:ActiveProcessorCount=4 passes all
  219 frontend tests, 616 Java unit/HTTP tests and five packaged-application
  integration tests, with no failures/errors/skips. This includes all 12 MCP
  HTTP tests. TypeScript and production packaging pass.
- All 14 deployment-rendering checks pass; they do not deploy anything.
- Local evidence: /tmp/pp-release-0.2.4-20261103/; pre-fix reproduction and stacks:
  /tmp/pp-ci-diagnosis-atavK3Ww/. Only temporary synthetic databases are used.
- Prior runtime/browser/security qualification remains dated separately in
  [the 0.2.3 report](RELEASE_VERIFICATION.md). It is not a fresh image scan or
  browser qualification of the new registry artifact.

## Publication contract

VERSION is 0.2.4; a new annotated v0.2.4 tag must match it. Existing tags are
not moved. The Container workflow validates the actual source commit at four
visible CPUs before building linux/amd64 and linux/arm64 images. The tag push
publishes ghcr.io/sepa79/pocketplanner:v0.2.4, latest and sha-<full-commit>.

Check the completed tag run and registry manifest digest plus each platform's
org.opencontainers.image.revision and version labels; dispatch/push is not
publication success. Runtime /api/info must report 0.2.4. This report records
the pre-publication local gate; registry results are checked after CI finishes.
No server deployment, operational plan transfer or PH/PD release is included.
