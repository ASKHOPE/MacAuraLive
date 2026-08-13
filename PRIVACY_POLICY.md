# MacAura Privacy Policy

**Last Updated: August 14, 2026**

At **MacAura**, your privacy is our top priority. MacAura is designed as a **100% local, on-device application** for macOS.

---

## 1. Zero Data Collection & Telemetry

- **No Tracking:** MacAura does **not** collect, store, transmit, or analyze any personal data, usage metrics, device identifiers, or crash reports.
- **No Analytics:** There are zero analytics SDKs, tracking pixels, or third-party telemetry scripts embedded in MacAura.
- **No External Servers:** MacAura operates completely offline, except when you explicitly use AI generation features with your own configured API keys.

---

## 2. Secure API Key Storage

- All API keys entered for AI wallpaper generation (OpenAI, Claude, Gemini, OpenRouter) are stored exclusively in your macOS system **Keychain** using Apple's `Security.framework` (`kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- API keys are protected by your Mac's hardware Secure Enclave. They are **never** saved to `UserDefaults`, plaintext files, or external servers.

---

## 3. macOS Permissions Usage

MacAura requests the following system permissions solely for local functionality:

| Permission | Purpose | Data Handling |
| :--- | :--- | :--- |
| **Screen Recording** (`CGPreflightScreenCaptureAccess`) | Detects when a full-screen application or game is active to automatically pause rendering and save 100% GPU/CPU power. | **Zero recording or storage.** Window bounds are checked strictly in real-time memory. No pixels, screen content, or audio are ever recorded, saved, or transmitted. |
| **File System Access** | Allows you to select and import wallpapers from your local disk or monitored folders (`~/Documents/MacauraApp/`). | Access is strictly local to your chosen files. |
| **System Startup** (`SMAppService`) | Enables MacAura to launch silently in your menu bar when macOS boots. | Managed entirely by macOS `ServiceManagement` APIs. |

---

## 4. Third-Party AI APIs

If you choose to use the AI Wallpaper Generator feature:
- Outbound HTTPS requests are sent directly to the official provider API endpoint (e.g., `api.openai.com`, `api.anthropic.com`, `generativelanguage.googleapis.com`, or `openrouter.ai`).
- Prompts entered into the AI playground are transmitted to your selected AI provider subject to that provider's privacy policy.

---

## 5. Contact & Questions

If you have any privacy questions or concerns, please review the source code directly on GitHub or open an issue in the official repository.
