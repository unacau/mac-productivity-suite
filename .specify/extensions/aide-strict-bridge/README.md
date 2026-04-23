# AIDE-Strict Bridge

Automated CLI hooks bridging the **AIDE** workflow with **Superpowers** and **Checkpoint** extensions.

This extension ensures that every step of your AI-Driven Engineering (AIDE) process follows senior engineering standards by automatically triggering test-driven development gates, requirement verification, and incremental commits.

## Features
- **Automatic Checkpoints**: Automatically triggers `/speckit.checkpoint.commit` after vision, roadmap, progress, and queue updates.
- **Spec Review**: Automatically triggers `/speckit.superb.review` after a work item spec is generated to ensure it is TDD-ready.
- **TDD Enforcement**: Automatically triggers `/speckit.superb.tdd` before work item execution.
- **Evidence-Based Completion**: Automatically triggers `/speckit.superb.verify` before implementation is marked complete.

## Installation

This extension can be installed directly from its local directory:

```bash
specify extension add aide-strict-bridge --dev <path-to-this-folder>
```

## How it Works
The extension registers native Spec Kit hooks that listen for AIDE lifecycle events. When you run an AIDE command (like `/speckit.aide.execute-item`), the Specify CLI automatically pauses to run the bridged Superpowers or Checkpoint commands before and after the main execution.
