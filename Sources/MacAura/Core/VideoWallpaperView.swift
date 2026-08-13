import AppKit
import AVFoundation

public class VideoWallpaperView: NSView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    
    public init(videoURL: URL, volume: Double = 0.0, isMuted: Bool = true) {
        super.init(frame: .zero)
        setupPlayer(url: videoURL, volume: volume, isMuted: isMuted)
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var timeObserverToken: Any?
    
    public func setupPlayer(url: URL, volume: Double = 0.0, isMuted: Bool = true) {
        self.wantsLayer = true
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("[VideoWallpaperView] Video file does not exist at: \(url.path)")
            return
        }
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.player = queuePlayer
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = self.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.layer?.addSublayer(layer)
        self.playerLayer = layer
        
        queuePlayer.volume = isMuted ? 0.0 : Float(volume)
        queuePlayer.isMuted = isMuted
        queuePlayer.play()
        
        // Add periodic time observer for playback progress UI
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = queuePlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak queuePlayer] time in
            guard let player = queuePlayer, let item = player.currentItem else { return }
            let durSec = item.duration.seconds
            let curSec = time.seconds
            if !durSec.isNaN && !durSec.isInfinite && durSec > 0 {
                DispatchQueue.main.async {
                    WallpaperEngine.shared.updatePlaybackPosition(current: curSec, duration: durSec)
                }
            }
        }
        
        let placement = AppSettings.shared.wallpaperPlacement
        let zoom = AppSettings.shared.wallpaperZoom
        setPlacement(placement: placement, zoom: zoom)
    }
    
    public func seek(to seconds: Double) {
        guard let player = player else { return }
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func setPlacement(placement: String, zoom: Double = 1.0) {
        guard let layer = playerLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch placement {
        case "fit":
            layer.videoGravity = .resizeAspect
            layer.transform = CATransform3DIdentity
        case "stretch":
            layer.videoGravity = .resize
            layer.transform = CATransform3DIdentity
        case "center":
            layer.videoGravity = .resizeAspect
            layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
        case "zoom":
            layer.videoGravity = .resizeAspectFill
            let scale = CGFloat(zoom)
            layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
        default: // "fill"
            layer.videoGravity = .resizeAspectFill
            layer.transform = CATransform3DIdentity
        }
        CATransaction.commit()
    }
    
    public override func layout() {
        super.layout()
        playerLayer?.frame = self.bounds
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func play() {
        player?.play()
    }
    
    public func setVolume(_ volume: Double, isMuted: Bool) {
        player?.volume = isMuted ? 0.0 : Float(volume)
        player?.isMuted = isMuted
    }
    
    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        playerLooper?.disableLooping()
        playerLooper = nil
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
    }
}
