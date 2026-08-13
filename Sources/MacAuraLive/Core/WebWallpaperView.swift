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
            const canvas = document.getElementById('c') || document.querySelector('canvas') || document.querySelector('img') || document.querySelector('video');
            if (!canvas) return;

            canvas.style.transition = 'transform 0.2s ease, object-fit 0.2s ease';
            if ("\(placement)" === "fit") {
                canvas.style.objectFit = 'contain';
                canvas.style.transform = 'scale(1)';
                canvas.style.transformOrigin = 'center center';
            } else if ("\(placement)" === "stretch") {
                canvas.style.objectFit = 'fill';
                canvas.style.width = '100vw';
                canvas.style.height = '100vh';
                canvas.style.transform = 'scale(1)';
            } else if ("\(placement)" === "center") {
                canvas.style.objectFit = 'none';
                canvas.style.transform = 'scale(1)';
                canvas.style.transformOrigin = 'center center';
            } else if ("\(placement)" === "zoom") {
                canvas.style.objectFit = 'cover';
                canvas.style.transform = 'scale(\(zoom))';
                canvas.style.transformOrigin = 'center center';
            } else { // "fill" (cover)
                canvas.style.objectFit = 'cover';
                canvas.style.transform = 'scale(1)';
                canvas.style.transformOrigin = 'center center';
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
