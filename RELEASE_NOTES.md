## What's Changed in v1.1.7

### 🛡️ Security & Hardening (Critical Vulnerability Remediation)
* **Cryptographic Keychain Verification:** Enforced SHA-256 receipt token verification (`pro_receipt_token`) for Keychain licenses, preventing unauthorized offline license spoofing.
* **Accessibility Memory Safety:** Replaced forced cast `as!` with CoreFoundation type validation (`AXUIElementGetTypeID`), eliminating fatal SIGABRT crashes.
* **Terminal & Password Vault Protection:** Added 9 modern terminal emulators (Ghostty, Kitty, Alacritty, WezTerm, Warp, iTerm2) and password vaults (Dashlane, Enpass, NordPass, Signal) to Copy-on-Select sensitive blacklist.
* **Path Traversal Shield:** Prevented directory traversal via profile avatar filename (`gaia_picture_file_name`) with strict canonical path boundary checks.
* **CLI Flag Injection Prevention:** Sanitized Chromium profile directory names in cold start launcher to disallow arbitrary argument injection.
* **Gatekeeper Integrity Enforcement:** Added deep binary structure and code signature verification (`codesign --verify --deep --strict`) before quarantine removal in `install.sh`.
* **Diagnostic Report Isolation:** Restricted temporary log directory permissions to `0700` and export zip archive to `0600` to prevent cross-process data leakage.
* **URL Scheme Guard:** Enforced `https` protocol enforcement on release notification links to block arbitrary URL handler execution.

### ⚡ Improvements & Quality Gates
* **Bundle Validation:** Added `.app` extension validation to custom application pinning (`registerCustomApp`).
* **Test Suite Expansion:** Added comprehensive security regression test suite (99 passing tests in <0.9s).
