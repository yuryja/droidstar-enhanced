---
name: security-verification
description: Checklist and procedures to verify security flaws before uploading or committing code.
---

# Security Verification Guidelines

Before making any commits or uploading code, you MUST always perform a security verification. Failure to verify security can lead to compromised data or unstable builds.

## 1. Static Analysis & Dependency Checking
- **Check Dependencies**: Ensure Qt and any third-party libraries (like Codec2) are up to date and do not contain known CVEs.
- **Input Validation**: Validate all user inputs. Do not assume data coming from the UI or network is safe.
- **Buffer Overflows**: In C/C++, always check buffer bounds. Prefer `std::string` or `std::vector` over raw C-arrays (`char[]`).

## 2. Secrets and Credentials
- **No Hardcoded Secrets**: Ensure that NO API keys, passwords, private certificates, or sensitive configuration details are hardcoded in the source code.
- **`.gitignore`**: Verify that sensitive files (e.g., `.env`, local configurations, `.DS_Store`) are ignored and will not be pushed to the repository.

## 3. Network Security
- **Secure Connections**: If the application communicates over the network, ensure it uses secure protocols (TLS/SSL).
- **Certificate Validation**: Do not bypass certificate validation in Qt (`QSslSocket`).

## 4. Build Integrity
- Ensure `codesign` is appropriately applied if releasing a `.app` or `.dmg` on macOS, ensuring no malicious code has been injected post-build.

## Pre-Commit Security Checklist
- [ ] Did I hardcode any secrets, passwords, or keys? (Must be NO)
- [ ] Are buffer boundaries respected in all modified C++ code? (Must be YES)
- [ ] Is all external data validated before processing? (Must be YES)
- [ ] Have I checked the `.gitignore` so no sensitive files are staged? (Must be YES)

If any of the above checks fail, **DO NOT COMMIT**. Fix the issue first.
