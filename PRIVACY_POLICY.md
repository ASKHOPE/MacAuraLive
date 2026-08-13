# MacAuraLive Privacy Policy

**Last Updated: August 14, 2026**

At **MacAuraLive**, your privacy is our top priority. MacAuraLive is designed as a **100% local, on-device application** for macOS.

---

## 1. Zero Data Collection & Telemetry by MacAuraLive

- **No Tracking:** MacAuraLive does **not** collect, store, transmit, or analyze any personal data, usage metrics, device identifiers, or crash reports.
- **No Analytics:** There are zero analytics SDKs, tracking pixels, or third-party telemetry scripts embedded in MacAuraLive.
- **No Middleman Servers:** MacAuraLive runs completely on your Mac. We do not host or operate proxy, analytics, or user-tracking servers.

---

## 2. Marketplace & Third-Party Content Plugins (Unsplash, Pixabay, Pexels)

MacAuraLive includes modular plugins allowing you to discover, search, and download wallpapers from third-party content providers:
- **Direct HTTPS Connection:** When you use Marketplace plugins, requests are made **directly from your Mac** to the respective provider's official API servers:
  - **Unsplash API:** `api.unsplash.com` & `images.unsplash.com`
  - **Pixabay API:** `pixabay.com/api/` & `cdn.pixabay.com`
  - **Pexels API:** `api.pexels.com` & `images.pexels.com`
- **Third-Party Server Logging & Tracking:** Because connections are made directly to third-party endpoints, each provider may process and log standard network traffic information (such as your public IP address, user-agent, and requested search keywords) under their respective privacy policies:
  - [Unsplash Privacy Policy](https://unsplash.com/privacy)
  - [Pixabay Privacy Policy](https://pixabay.com/service/privacy/)
  - [Pexels Privacy Policy](https://www.pexels.com/privacy-policy/)
- **Local Asset Persistence:** Downloaded wallpapers and video assets are saved permanently to your Mac (`~/Library/Application Support/MacAuraLive/Wallpapers/Downloads/`). Once stored on your local disk, wallpapers are rendered 100% offline without further network connections.

---

## 3. Secure API Key Storage (macOS Keychain)

- All API keys entered for AI Generation (OpenAI, Claude, Gemini, OpenRouter) and Marketplace Plugins (Unsplash, Pixabay, Pexels) are stored exclusively in your macOS system **Keychain** using Apple's `Security.framework` (`kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- API keys are protected by your Mac's hardware Secure Enclave. They are **never** saved to `UserDefaults`, plaintext files, or external servers.

---

## 4. macOS System Permissions Usage

MacAuraLive requests the following system permissions solely for local device functionality:

| Permission | Purpose | Data Handling |
| :--- | :--- | :--- |
| **File System Access (Read/Write)** | Allows importing local files/folders, storing downloaded 4K wallpapers in `~/Library/Application Support/MacAuraLive/Wallpapers/Downloads/`, and persisting custom manifests. | Access is strictly local to your device. No files are uploaded to external servers. |
| **Network Access (Client HTTPS)** | Enables searching online plugins (Unsplash, Pixabay, Pexels), downloading media files, and communicating with user-configured AI providers. | Direct client-to-API requests over TLS 1.3 encryption. |
| **Screen Recording** (`CGPreflightScreenCaptureAccess`) | Detects when a full-screen application or game is active to automatically pause rendering and save 100% GPU/CPU power. | **Zero recording or storage.** Window bounds are checked strictly in real-time memory. No pixels, screen content, or audio are ever recorded, saved, or transmitted. |
| **System Startup** (`SMAppService`) | Enables MacAuraLive to launch silently in your menu bar when macOS boots. | Managed entirely by macOS `ServiceManagement` APIs. |

---

## 5. Third-Party AI APIs

If you choose to use the AI Wallpaper Generator feature:
- Outbound HTTPS requests are sent directly to the official provider API endpoint (e.g., `api.openai.com`, `api.anthropic.com`, `generativelanguage.googleapis.com`, or `openrouter.ai`).
- Prompts entered into the AI playground are transmitted to your selected AI provider subject to that provider's privacy policy.

---

## 6. Contact & Questions

If you have any privacy questions or concerns, please review the open source code directly on GitHub or open an issue in the official repository.
