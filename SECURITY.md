# MacAuraLive Security Policy & Practices

## Security Principles

MacAuraLive is built following strict macOS security standards:
- **Zero Third-Party Binary Dependencies:** Built entirely with native Swift and Apple's core frameworks (`SwiftUI`, `AppKit`, `AVFoundation`, `WebKit`, `CryptoKit`, `Security`).
- **Hardware-Enclave Keychain Storage:** All sensitive credentials are encrypted at rest using macOS system Keychain APIs (`Security.framework`).
- **No Unsafe Process Execution:** No `Process()`, `NSTask`, `eval()`, or `system()` execution functions exist in runtime code.
- **Input & Path Traversal Sanitization:** User file paths and inputs are sanitized via `SecurityHardeningManager` to block path traversal attempts (`../`).
- **Single-Instance Enforcement:** Prevents duplicate process spoofing or memory race conditions.

---

## Reporting a Vulnerability

If you discover a security vulnerability in MacAuraLive:
1. **Do NOT open a public GitHub issue.**
2. Report the vulnerability privately by opening a security advisory or contacting the maintainer directly.
3. Include a description of the issue, steps to reproduce, and potential impact.

We take security reports seriously and will respond promptly to investigate and patch verified vulnerabilities.
