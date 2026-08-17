# MacAuraLive — Third-Party Notices & Licenses

**Last Updated: August 17, 2026**

MacAuraLive is an open-source macOS live wallpaper engine licensed under the **MIT License**. This document acknowledges and credits the third-party media assets, content platforms, and technologies utilized in MacAuraLive.

---

## 1. Bundled Media Assets

### A. Video Wallpapers

- **Abstract Blue Motion Waves Loop (`ShivaayWaves/wallpaper.mp4`)**
  - **Creator:** Shivaay Singh (Pixabay ID: `mrbones03-33188032`)
  - **Source:** [Pixabay Video 270983](https://pixabay.com/videos/id-270983/)
  - **License:** [Pixabay Content License](https://pixabay.com/service/license-summary/) (Free for commercial and non-commercial use, no attribution strictly required, attribution gratefully provided).

---

### B. Bundled Static Wallpapers

- **Turbulent Ocean Water Swirls (`TurbulentOcean/wallpaper.jpg`)**
  - **Photographer:** Kristaps Ungurs
  - **Source:** [Unsplash Photo XD5oKCerKCQ](https://unsplash.com/photos/XD5oKCerKCQ)
  - **License:** [Unsplash License](https://unsplash.com/license) (Free to use under Unsplash Terms).

- **Abstract Blue Mountain Ridges (`MountainRidges/wallpaper.jpg`)**
  - **Photographer:** Oxana Golubets
  - **Source:** [Unsplash Photo lXHx-zumrJs](https://unsplash.com/photos/lXHx-zumrJs)
  - **License:** [Unsplash License](https://unsplash.com/license) (Free to use under Unsplash Terms).

- **Abstract Blue Layered Curves (`BlueCurves/wallpaper.jpg`)**
  - **Photographer:** Hassaan Here
  - **Source:** [Unsplash Photo Ype8P9pAjXQ](https://unsplash.com/photos/Ype8P9pAjXQ)
  - **License:** [Unsplash License](https://unsplash.com/license) (Free to use under Unsplash Terms).

- **Deep Cosmos Nebula & Starfield (`DeepSpaceNebula/wallpaper.jpg`)**
  - **Source:** NASA / Unsplash Space Archive
  - **License:** Public Domain / [Unsplash License](https://unsplash.com/license).

- **Alpine Glacier Mountain Peak (`AlpineGlacier/wallpaper.jpg`)**
  - **Photographer:** Unsplash Community Contributor
  - **License:** [Unsplash License](https://unsplash.com/license).

---

## 2. Procedural Canvas & WebGL Shaders

The built-in live procedural shaders (Aurora Borealis, Matrix Digital Rain, Cyberpunk Synthwave, and 3D Particle Wave) are original custom implementations developed for MacAuraLive and licensed under the project's root **MIT License**.

---

## 3. Online Content Platform Integrations (Marketplace Plugins)

MacAuraLive connects directly from the user's Mac over encrypted HTTPS to public content provider APIs. No intermediary proxy servers are operated.

- **Unsplash API:** Content accessed via Unsplash plugins is subject to the [Unsplash API Terms of Use](https://unsplash.com/terms) and [Unsplash License](https://unsplash.com/license). All photographer credits, avatar links, and referral tags (`utm_source=MacAuraLive&utm_medium=referral`) are strictly maintained.
- **Pixabay API:** Content accessed via Pixabay plugins is subject to the [Pixabay Terms of Service](https://pixabay.com/service/terms/) and [Pixabay Content License](https://pixabay.com/service/license-summary/).
- **Pexels API:** Content accessed via Pexels plugins is subject to the [Pexels Terms of Service](https://www.pexels.com/terms/) and [Pexels License](https://www.pexels.com/license/).

---

## 4. AI Generation Providers (BYOK - Bring Your Own Key)

MacAuraLive provides client-side integrations for user-supplied API keys for AI scene planning. All outbound calls are direct TLS connections between the user's machine and the respective provider endpoint:

- **OpenAI API:** Subject to OpenAI [Terms of Use](https://openai.com/policies/terms-of-use/) and [Privacy Policy](https://openai.com/policies/privacy-policy/).
- **Anthropic Claude API:** Subject to Anthropic [Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms).
- **Google Gemini API:** Subject to Google [Generative AI Additional Terms of Service](https://ai.google.dev/terms).
- **OpenRouter API:** Subject to OpenRouter [Terms of Service](https://openrouter.ai/terms).

---

## 5. Apple Inc. Technologies & Frameworks

MacAuraLive is built using standard native macOS software development kits and frameworks provided by Apple Inc.:
- `SwiftUI`, `AppKit`, `AVFoundation`, `WebKit`, `CryptoKit`, `Security`, `ServiceManagement`, `CoreGraphics`, `Metal`.

Apple, macOS, Metal, AVFoundation, SwiftUI, and AppKit are registered trademarks of **Apple Inc.** in the U.S. and other countries. MacAuraLive is an independent open-source project and is not endorsed by, affiliated with, or sponsored by Apple Inc.
