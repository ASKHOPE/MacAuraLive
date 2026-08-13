# MacAuraLive Terms of Service

**Last Updated: August 14, 2026**

Welcome to **MacAuraLive Live Wallpaper Engine for macOS** ("MacAuraLive", "the Software", "we", "us", or "our"). By downloading, installing, compiling, or using MacAuraLive, you ("User", "you") agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not install or use the Software.

---

## 1. Open Source License Grant

MacAuraLive is licensed under the **MIT License**. You are granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the Software, subject to the conditions set forth in the [LICENSE](LICENSE) file.

---

## 2. User Responsibilities & Content Rights

### A. User-Imported Media & Assets
MacAuraLive enables users to import custom video loops (`.mp4`, `.mov`, `.m4v`), animated GIFs (`.gif`), static images (`.jpeg`, `.png`, `.heic`), and interactive WebGL/HTML5 shaders.
- **Copyright Compliance:** You represent and warrant that you hold all necessary rights, licenses, or permissions for any media or shaders you import into MacAuraLive.
- **Third-Party Rights:** MacAuraLive does not host, distribute, or claim ownership over third-party media imported by users. You are solely responsible for ensuring your use of imported media complies with applicable copyright, trademark, and intellectual property laws.

### B. Marketplace & Online Content Plugins (Unsplash, Pixabay, Pexels)
MacAuraLive provides built-in plugin adapters for searching, discovering, and downloading wallpapers from third-party platforms:
- **Direct Client-to-API Communication:** When browsing or downloading media through Marketplace plugins, your device connects directly to the official endpoints of **Unsplash**, **Pixabay**, or **Pexels** over encrypted HTTPS. MacAuraLive does not operate an intermediary proxy or relay server.
- **Compliance with Provider Terms:** Your use of third-party media is subject to the respective terms and licenses of each provider:
  - **Unsplash:** Subject to the [Unsplash Terms of Service](https://unsplash.com/terms) and [Unsplash License](https://unsplash.com/license). Photographer attribution and direct links are preserved.
  - **Pixabay:** Subject to the [Pixabay Terms of Service](https://pixabay.com/service/terms/) and [Pixabay Content License](https://pixabay.com/service/license-summary/).
  - **Pexels:** Subject to the [Pexels Terms of Service](https://www.pexels.com/terms/) and [Pexels License](https://www.pexels.com/license/).
- **Local Storage & Offline Functionality:** Downloaded wallpapers and video loops are saved directly on your local disk under `~/Documents/MacAuraLiveApp/` in their respective categorized folders (`livewallpaper`, `staticwallpaper`, `gif`). Once downloaded, assets run locally on your device without recurring network traffic.
- **User-Configured API Keys:** If you provide custom API keys for Unsplash, Pixabay, or Pexels, they are stored exclusively in your local macOS **Keychain** (`Security.framework`) and protected by the hardware Secure Enclave.

### C. AI Generation API Keys
MacAuraLive includes an optional AI Wallpaper Generator feature allowing integration with third-party Large Language Model (LLM) provider APIs (such as OpenAI, Anthropic Claude, Google Gemini, or OpenRouter).
- You are solely responsible for managing your own API keys and complying with the respective API Terms of Service of each provider.
- All API keys are stored exclusively in your local macOS Keychain. MacAuraLive never transmits your API keys to any third-party server other than the official provider API endpoint configured by you.

---

## 3. Hardware, Battery, & Performance Disclaimer

Continuous 60 FPS live video wallpaper playback and procedural WebGL 3D shader rendering naturally increase GPU, CPU, and battery power consumption.

- **"AS IS" Operation:** MacAuraLive is provided "AS IS" without any performance guarantees.
- **Battery Usage:** Users operating laptop computers on battery power are strongly encouraged to enable the "Pause on Battery" feature in MacAuraLive App Preferences.
- **Hardware Limitation:** MacAuraLive and its developers shall not be held liable for any hardware degradation, thermal throttling, overheating, battery degradation, or system instability resulting from continuous wallpaper execution.

---

## 4. Limitation of Liability & Warranty Disclaimer

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, MACAURA IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

IN NO EVENT SHALL THE AUTHORS, COPYRIGHT HOLDERS, OR CONTRIBUTORS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## 5. Trademark Notices

- **Apple, macOS, Metal, AVFoundation, SwiftUI, and AppKit** are registered trademarks of **Apple Inc.**
- **Unsplash, Pixabay, and Pexels** are trademarks or registered trademarks of their respective owners.
- MacAuraLive is an independent open-source software project and is **not** affiliated with, endorsed by, sponsored by, or associated with Apple Inc., Unsplash Inc., Canva Pty Ltd (Pixabay/Pexels), or any third-party media rights holder.

---

## 6. Governing Law & Updates

These Terms shall be governed by and construed in accordance with standard open-source licensing principles. We reserve the right to update these Terms at any time by updating this document on GitHub.

For questions regarding these Terms, please open an issue on the official GitHub repository.
