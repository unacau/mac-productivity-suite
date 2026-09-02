# Implementation Plan: CI/CD Pipeline Modernization & Release Lifecycle

## Overview
Following the successful diagnosis and resolution of the GitHub Actions CI process hang, this plan structures the remaining operational maintenance into three vertical, verifiable tasks:
1. Migrating to Swift 6 Toolchain-Native Testing (eliminating 350+ `swift-syntax` source files and dropping CI build time from 2m+ to ~30s).
2. Modernizing GitHub Actions Runner Workflows (resolving PR #1 and Node.js 20 deprecation).
3. Executing Semantic Version Bump & Release Verification (`v2.4.10`).

---

## Architecture & Design Decisions
- **Toolchain-Native `import Testing`**: Swift 6 natively bundles the Swift Testing framework. Removing the external `apple/swift-testing` package dependency from `Package.swift` eliminates the deprecation warnings and avoids building the heavy `swift-syntax` macro engine in CI.
- **Workflow Action Modernization**: Upgrading `actions/checkout` to `@v7` resolves GitHub's Node 20 runner deprecation warnings and synchronizes Dependabot PR #1.
- **Strict Semantic Version Discipline**: Adhere to `make bump-patch` so `VERSION.txt`, `BUILD.txt`, and `src/NativeStandaloneApp/Info.plist` remain in lockstep.

---

## Task List

### Phase 1: Toolchain & Dependency Modernization
- [ ] Task 1: Migrate to Toolchain-Native Swift Testing & Clean Deprecations
- [ ] Checkpoint: Swift Testing Clean Build

### Phase 2: Workflow & Runner Modernization
- [ ] Task 2: Update CI Actions to Node 24 Runtimes & Resolve PR #1
- [ ] Checkpoint: CI Pipeline Green

### Phase 3: Release Lifecycle
- [ ] Task 3: Semantic Version Bump to v2.4.10 & Release Packaging
- [ ] Checkpoint: Production Release Ready

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Swift Testing toolchain compatibility across macOS versions | Low | Project targets macOS 14.0+ and uses Xcode 16+, where native `Testing` is standard. |
| Dependabot merge conflicts | Low | PR #1 touches only 1 line in `.github/workflows/ci.yml`. Fast-forward or direct rebase. |
| Unintended cache invalidation | Low | Cache key uses `hashFiles('**/Package.resolved')`, cleanly updating on dependency prune. |

---

## Open Questions & Decisions
- Does the user want to automatically publish `v2.4.10` to GitHub Releases via `./release.sh`, or prepare the local artifacts (`dist/MacProductivitySuite.dmg` and `dist/MacProductivitySuite-Full.pkg`) first for review?
