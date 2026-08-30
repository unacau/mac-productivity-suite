# Mac Productivity Suite Shipping Process

This document defines the process for safely shipping updates to the Mac Productivity Suite, aligning with the `shipping-and-launch` skill for production readiness.

## 1. Pre-Launch Checklist (Definition of Done)

Before opening a PR that triggers a new release, ensure the following quality gates are met:

- **Code Quality**:
  - `tests/run_tests.sh` passes successfully.
  - `build_native_app.sh` compiles cleanly without warnings.
  - Telemetry is present via `AppLogger` (No raw `print()` statements).
- **Security**:
  - Sparkle EdDSA private keys remain in GitHub Secrets, NEVER committed.
  - `AXIsProcessTrusted` is strictly verified before hooking global macOS events.

## 2. CI/CD Automated Workflow

1. **Pull Requests**: Pushing to any branch or opening a PR triggers `.github/workflows/ci.yml`. This runs the Swift test suite and native build.
2. **Release (Tagging)**: When a commit is tagged (e.g., `v2.1.0`) and pushed to `main`, `.github/workflows/release.yml` triggers.
   - It builds the universal macOS binary.
   - It signs the `dist/MacProductivitySuite.dmg` using the Sparkle Private Key.
   - It updates the `appcast.xml` feed automatically.
   - It drafts the GitHub Release for the artifact.

## 3. Staged Rollout via Sparkle

To prevent a bad release from hitting all users instantly, updates should use Sparkle's phased rollout mechanism. 

When updating `appcast.xml`, the `<sparkle:phasedRolloutInterval>` tag should be used to gradually distribute the update over a 7-day period.

```xml
<item>
    <title>Version 2.1</title>
    <sparkle:version>2.1.0</sparkle:version>
    <sparkle:phasedRolloutInterval>86400</sparkle:phasedRolloutInterval> <!-- 1 day interval per step (7 days total) -->
    <!-- ... -->
</item>
```

**Rollout Monitoring**:
- Monitor GitHub Issues and crash reports from users closely during the 7-day rollout window.

## 4. Rollback Strategy

macOS does not allow "downgrading" apps seamlessly via Sparkle due to security constraints. If a critical issue is discovered in production:

1. **Halt the Rollout**: Immediately remove the `<item>` from the `appcast.xml` feed.
2. **Revert the Code**: Revert the offending PR/commit on the `main` branch.
3. **Roll-Forward Release**: Cut a *new* release (e.g., `v2.1.1`) containing the reverted, stable code.
4. **Push Tag**: Push the new tag to trigger the release pipeline so users on the broken version are immediately updated to the "hotfix" (which is actually the reverted code).
