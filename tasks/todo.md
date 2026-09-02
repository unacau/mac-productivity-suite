# Tasks: CI/CD Pipeline Modernization & Release Lifecycle

## Task 1: Migrate to Toolchain-Native Swift Testing & Clean Deprecations

**Description:** Evaluated removing `apple/swift-testing` package dependency. Confirmed that maintaining `apple/swift-testing` is required for universal compilation on systems with macOS Command Line Tools (without full Xcode IDE installation). Decoupled entry points and added `-F Frameworks` to test targets.

**Acceptance criteria:**
- [x] Evaluated toolchain-native vs package Swift Testing requirements.
- [x] Retained universal CLT compatibility while isolating executable entry points.
- [x] All 13 unit and integration tests compile and pass with zero failures.

**Verification:**
- [x] Tests pass: `swift test` (13/13 passed in 0.78s)
- [x] Build succeeds: `./tests/run_tests.sh`

**Dependencies:** None

---

## Checkpoint: Foundation
- [x] All unit and integration tests pass cleanly via SPM.
- [x] Local build passes.

---

## Task 2: Update CI Actions to Node 24 Runtimes & Resolve PR #1

**Description:** Upgrade GitHub Actions workflow steps to use modern action versions compatible with Node.js 24 (`actions/checkout@v7` and `actions/cache@v6`). Closed Dependabot PR #1 and verified GitHub Actions runs cleanly without deprecation annotations.

**Acceptance criteria:**
- [x] `.github/workflows/ci.yml` uses `actions/checkout@v7`.
- [x] `.github/workflows/ci.yml` uses `actions/cache@v6`.
- [x] Dependabot PR #1 is cleanly closed/superseded.
- [x] GitHub Actions workflow passes with zero runner deprecation annotations.

**Verification:**
- [x] Remote CI run passes: [Run #33647579932](https://github.com/unacau/mac-productivity-suite/actions/runs/33647579932) (1m 40s, green)
- [x] Check annotations: 0 deprecation annotations
- [x] PR status: PR #1 closed

**Dependencies:** Task 1

---

## Checkpoint: Workflow & Runner Integrity
- [x] Remote CI pipeline completes under 2 minutes (1m 40s).
- [x] Zero warnings or deprecation annotations in GitHub Actions UI.

---

## Task 3: Semantic Version Bump to v2.4.10 & Release Packaging

**Description:** Bump patch version to `v2.4.10` to capture the CI test isolation fixes, entry point decoupling, and workflow action updates. Verify synchronized versioning across `VERSION.txt`, `BUILD.txt`, and `Info.plist`, build universal binaries and offline bundles, and prepare release artifacts.

**Acceptance criteria:**
- [x] `VERSION.txt` updated to `2.4.10` and `BUILD.txt` incremented to `15`.
- [x] `src/NativeStandaloneApp/Info.plist` synchronized with version `2.4.10` and build `15`.
- [x] `dist/MacProductivitySuite.dmg` built and verified (`arm64` + `x86_64`).
- [ ] Ready for user sign-off to execute `./release.sh` or publish tag to GitHub Releases.

**Verification:**
- [x] Health check: `make health` (5/5 points passing)
- [x] Native build: `make native`
- [x] Version consistency: verified across all files

**Dependencies:** Task 1, Task 2

---

## Checkpoint: Complete
- [x] `make health` passes 100% of checks.
- [x] Distribution DMG package built.
- [ ] User approval to publish release.
