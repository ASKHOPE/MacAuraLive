import AppKit
import WebKit

public class WebWallpaperView: NSView, WKNavigationDelegate {
    private var webView: WKWebView?
    private var customSettingsJson: String = "{}"
    
    public init(url: URL) {
        super.init(frame: .zero)
        setupWebView(url: url)
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWebView(url: URL) {
        self.wantsLayer = true
        
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.mediaTypesRequiringUserActionForPlayback = []
        SecurityHardeningManager.shared.configureSecureWebView(config)
        
        // Inject the MacAuraLive SDK Polyfill
        let sdkScriptSource = """
        window.macAura = {
            state: {
                system: { batteryLevel: 1.0, isPluggedIn: true, performanceTier: "Full (60 FPS)", fps: 60 },
                mouse: { x: 0, y: 0 },
                settings: {}
            },
            updateListeners: [],
            initListeners: [],
            onInit: function(fn) { this.initListeners.push(fn); },
            onUpdate: function(fn) { this.updateListeners.push(fn); },
            _triggerInit: function(config) {
                this.initListeners.forEach(fn => fn(config));
            },
            _triggerUpdate: function(state) {
                this.state = state;
                this.updateListeners.forEach(fn => fn(state));
            }
        };
        """
        
        let userScript = WKUserScript(source: sdkScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: self.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        
        self.addSubview(webView)
        self.webView = webView
        
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        let placement = AppSettings.shared.wallpaperPlacement
        let zoom = AppSettings.shared.wallpaperZoom
        setPlacement(placement, zoom: zoom)
    }
    
    public func setPlacement(_ placement: String, zoom: Double = 1.0) {
        let js = """
        (function() {
            document.documentElement.style.margin = '0';
            document.documentElement.style.padding = '0';
            document.documentElement.style.width = '100vw';
            document.documentElement.style.height = '100vh';
            document.documentElement.style.overflow = 'hidden';
            
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.width = '100vw';
            document.body.style.height = '100vh';
            document.body.style.overflow = 'hidden';
            document.body.style.display = 'flex';
            document.body.style.justifyContent = 'center';
            document.body.style.alignItems = 'center';

            const element = document.getElementById('c') || document.querySelector('canvas') || document.querySelector('img') || document.querySelector('video');
            if (!element) return;

            element.style.position = 'absolute';
            element.style.top = '0';
            element.style.left = '0';
            element.style.width = '100vw';
            element.style.height = '100vh';
            element.style.margin = '0';
            element.style.padding = '0';
            element.style.transition = 'transform 0.2s ease, object-fit 0.2s ease';
            element.style.transformOrigin = 'center center';

            if ("\(placement)" === "fit") {
                element.style.objectFit = 'contain';
                element.style.transform = 'scale(\(zoom))';
            } else if ("\(placement)" === "stretch") {
                element.style.objectFit = 'fill';
                element.style.transform = 'scale(\(zoom))';
            } else if ("\(placement)" === "center") {
                element.style.objectFit = 'none';
                element.style.transform = 'scale(\(zoom))';
            } else if ("\(placement)" === "zoom") {
                element.style.objectFit = 'cover';
                element.style.transform = 'scale(\(zoom))';
            } else { // "fill" (stretch to fill screen / cover)
                element.style.objectFit = 'cover';
                element.style.transform = 'scale(\(zoom))';
            }
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func setCustomSettings(_ jsonString: String) {
        self.customSettingsJson = jsonString
        let triggerInit = "if (window.macAura) { window.macAura._triggerInit({ settings: \(jsonString) }); }"
        webView?.evaluateJavaScript(triggerInit, completionHandler: nil)
    }
    
    public func updateSDKState() {
        guard let webView = webView else { return }
        
        let battery = PerformanceManager.shared.batteryLevel
        let plugged = PerformanceManager.shared.isPluggedIn
        let tier = PerformanceManager.shared.currentTier.rawValue
        let fps = PerformanceManager.shared.targetFps
        let mouseLocation = NSEvent.mouseLocation
        
        let js = """
        (function() {
            if (window.macAura) {
                const newState = {
                    system: {
                        batteryLevel: \(battery),
                        isPluggedIn: \(plugged),
                        performanceTier: "\(tier)",
                        fps: \(fps)
                    },
                    mouse: { x: \(mouseLocation.x), y: \(mouseLocation.y) },
                    settings: \(customSettingsJson)
                };
                window.macAura._triggerUpdate(newState);
            }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public override func layout() {
        super.layout()
        webView?.frame = self.bounds
    }
    
    public func pause() {
        let js = """
        if (typeof pause === 'function') { pause(); }
        document.querySelectorAll('video, audio').forEach(el => el.pause());
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func resume() {
        let js = """
        if (typeof resume === 'function') { resume(); }
        document.querySelectorAll('video, audio').forEach(el => el.play());
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func setVolume(_ volume: Double, isMuted: Bool) {
        let effectiveVol = isMuted ? 0.0 : volume
        let js = """
        document.querySelectorAll('video, audio').forEach(el => {
            el.volume = \(effectiveVol);
            el.muted = \(isMuted ? "true" : "false");
        });
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    public func reload() {
        webView?.reload()
    }
    
    public func setPlaybackRate(_ rate: Float) {
        let js = """
        (function() {
            window.playbackRate = \(rate);
            window.playbackSpeed = \(rate);
            if (window.macAura) {
                window.macAura.playbackRate = \(rate);
                window.macAura.playbackSpeed = \(rate);
                if (typeof window.macAura._triggerUpdate === 'function' && window.macAura.state) {
                    window.macAura.state.playbackRate = \(rate);
                    window.macAura._triggerUpdate(window.macAura.state);
                }
            }
            document.querySelectorAll('video, audio').forEach(el => {
                el.playbackRate = \(rate);
            });
            if (typeof setPlaybackRate === 'function') { setPlaybackRate(\(rate)); }
            if (typeof setSpeed === 'function') { setSpeed(\(rate)); }
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let placement = AppSettings.shared.wallpaperPlacement
        let zoom = AppSettings.shared.wallpaperZoom
        setPlacement(placement, zoom: zoom)
        
        let volume = AppSettings.shared.audioVolume
        let isMuted = AppSettings.shared.isMuted
        setVolume(volume, isMuted: isMuted)
        
        updateSDKState()
    }
    
    deinit {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }
}
