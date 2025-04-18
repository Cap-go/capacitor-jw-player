import Foundation
import Capacitor
import JWPlayerKit
import AVKit // Import AVKit for AVAudioSession

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */

// Protocol for callback handling
protocol CallbackHandler {
    func notifyEventListener(_ eventName: String, data: [String: Any]?)
    func onPlayerDismissed()
}


@objc(JwPlayerPlugin)
public class JwPlayerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "JwPlayerPlugin"
    public let jsName = "JwPlayer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pause", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "seekTo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setVolume", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPosition", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setSpeed", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadPlaylist", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadPlaylistWithItems", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getAudioTracks", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCurrentAudioTrack", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setCurrentAudioTrack", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCaptions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCurrentCaptions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setCurrentCaptions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPlaylistIndex", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "currentPlaylist", returnType: CAPPluginReturnPromise)
    ]
    private var viewController: CustomPlayerViewController? = nil
    

    override public func load() {
        // Configure the audio session when the plugin loads
        setupAudioSession()
    }

    private func setupAudioSession() {
        print("[JWPlayer] Setting up AVAudioSession")
        do {
            // Configure audio session for playback and PiP
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
            print("[JWPlayer] AVAudioSession configured successfully for playback")
        } catch {
            print("[JWPlayer] Error setting up AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    @objc func initialize(_ call: CAPPluginCall) {
        print("[JWPlayer] initialize called")
        guard let licenseKey = call.getString("licenseKey") else {
            print("[JWPlayer] Error: licenseKey is missing")
            call.reject("licenseKey is required for initialize")
            return
        }
        
        print("[JWPlayer] Setting license key")
        JWPlayerKitLicense.setLicenseKey(licenseKey)
        print("[JWPlayer] License key set successfully")
        
        call.resolve()
    }
    
    @objc func play(_ call: CAPPluginCall) {
        print("[JWPlayer] play called with options: \(call.options)")
        guard let mediaUrlStr = call.getString("mediaUrl") else {
            print("[JWPlayer] Error: mediaUrl is missing")
            call.reject("mediaUrl is required for initialize")
            return
        }
        
        guard let mediaUrl = URL(string: mediaUrlStr) else {
            print("[JWPlayer] Error: mediaUrl is invalid URL: \(mediaUrlStr)")
            call.reject("mediaUrl is invalid URL")
            return
        }
        
        guard let mediaType = call.getString("mediaType") else {
            print("[JWPlayer] Error: mediaType is missing")
            call.reject("mediaType is required for initialize")
            return
        }
        
        if self.viewController != nil {
            print("[JWPlayer] Error: player is already active")
            call.reject("the player is already active")
            return
        }
        
        print("[JWPlayer] Media type: \(mediaType), URL: \(mediaUrl)")
        
        // Create configuration directly
        var config: JWPlayerConfiguration? = nil
        do {
            switch mediaType {
                case "video":
                    print("[JWPlayer] Creating video configuration")
                    let item = try JWPlayerItemBuilder()
                        .file(mediaUrl)
                        .build()
                    config = try JWPlayerConfigurationBuilder()
                        .playlist(items: [item])
                        .build()
                case "playlist":
                    print("[JWPlayer] Creating playlist configuration")
                    config = try JWPlayerConfigurationBuilder()
                        .playlist(url: mediaUrl)
                        .build()
                default:
                    print("[JWPlayer] Error: Invalid mediaType: \(mediaType)")
                    call.reject("Invalid mediaType. Must be either video or playlist")
                    return
            }
        } catch {
            print("[JWPlayer] Error creating configuration: \(error.localizedDescription)")
            call.reject("Error creating player configuration: \(error.localizedDescription)")
            return
        }
        
        guard let finalConfig = config else {
            print("[JWPlayer] Error: Configuration is nil after creation")
            call.reject("Failed to create player configuration")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            print("[JWPlayer] Creating player view controller with config")
            // Pass the configuration directly
            let viewController = CustomPlayerViewController(config: finalConfig, callbackHandler: self)
            viewController.modalPresentationStyle = .fullScreen
            self.viewController = viewController
            print("[JWPlayer] Resolving play call")
            call.resolve()
            print("[JWPlayer] Presenting view controller")
            self.bridge?.viewController?.present(viewController, animated: true)
            print("[JWPlayer] View controller presented")
        })
    }
    
    @objc func pause(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.pause()
            call.resolve()
        })
    }
    
    @objc func stop(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.stop()
            call.resolve()
        })
    }
    
    @objc func seekTo(_ call: CAPPluginCall) {
        guard let time = call.getDouble("time") else {
            call.reject("time parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.seek(to: TimeInterval(time))
            call.resolve()
        })
    }
    
    @objc func setVolume(_ call: CAPPluginCall) {
        guard let volume = call.getDouble("volume") else {
            call.reject("volume parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.volume = volume
            call.resolve()
        })
    }
    
    @objc func getPosition(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            call.resolve(["position": viewController.player.time.position])
        })
    }
    
    @objc func getState(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            call.resolve(["state": viewController.player.getState().rawValue])
        })
    }
    
    @objc func setSpeed(_ call: CAPPluginCall) {
        guard let speed = call.getDouble("speed") else {
            call.reject("speed parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.playbackRate = speed
            call.resolve()
        })
    }
    
    @objc func setPlaylistIndex(_ call: CAPPluginCall) {
        guard let index = call.getInt("index") else {
            call.reject("index parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            // Use the loadPlayerItemAt method which should be available
            do {
                viewController.player.loadPlayerItemAt(index: index)
                call.resolve()
            } catch {
                call.reject("Failed to set playlist index: \(error.localizedDescription)")
            }
        })
    }
    
    @objc func loadPlaylist(_ call: CAPPluginCall) {
        guard let playlistUrlStr = call.getString("playlistUrl") else {
            call.reject("playlistUrl parameter is required")
            return
        }
        
        guard let playlistUrl = URL(string: playlistUrlStr) else {
            call.reject("playlistUrl is invalid URL")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.loadPlaylist(url: playlistUrl)
            call.resolve()
        })
    }
    
    @objc func loadPlaylistWithItems(_ call: CAPPluginCall) {
        guard let playlist = call.getArray("playlist", [String: Any].self) else {
            call.reject("playlist parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            var items: [JWPlayerItem] = []
            
            for item in playlist {
                if let fileStr = item["file"] as? String, let url = URL(string: fileStr) {
                    do {
                        let playerItem = try JWPlayerItemBuilder()
                            .file(url)
                            .build()
                        items.append(playerItem)
                    } catch {
                        call.reject("Error creating playlist item: \(error.localizedDescription)")
                        return
                    }
                }
            }
            
            if !items.isEmpty {
                viewController.player.loadPlaylist(items: items)
                call.resolve()
            } else {
                call.reject("No valid playlist items found")
            }
        })
    }
    
    @objc func getAudioTracks(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            let audioTracks = viewController.player.audioTracks
            
            if audioTracks != nil && audioTracks.count > 0 {
                var results: [[String: Any]] = []
                for track in audioTracks {
                    let trackDict: [String: Any] = [
                        "language": track.extendedLanguageTag ?? "UNKNOWN",
                        "defaultTrack": track.defaultOption,
                        "name": track.name
                    ]
                    results.append(trackDict)
                }
                call.resolve(["tracks": results])
            } else {
                call.resolve(["tracks": []])
            }
        })
    }
    
    @objc func getCurrentAudioTrack(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            call.resolve(["index": viewController.player.currentAudioTrack])
        })
    }
    
    @objc func setCurrentAudioTrack(_ call: CAPPluginCall) {
        guard let index = call.getInt("index") else {
            call.reject("index parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            viewController.player.currentAudioTrack = index
            call.resolve()
        })
    }
    
    @objc func getCaptions(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            // JWPlayer iOS SDK doesn't have a direct way to get all caption tracks
            // But we can use the advanced settings to access them
            let captionsTrackId = viewController.player.currentCaptionsTrack
            
            // Create a basic response with just the current caption track
            let captionsArray: [[String: Any]] = [
                // Caption track 0 is usually "Off"
                ["index": 0, "label": "Off"],
                // If there's a current caption track that's not 0, add it
                ["index": captionsTrackId, "label": "Current"]
            ].filter { dict in
                // Only include the current track if it's not 0 (Off)
                if let index = dict["index"] as? Int, index == 0 || index == captionsTrackId {
                    return true
                }
                return false
            }
            
            call.resolve(["captions": captionsArray])
        })
    }
    
    @objc func getCurrentCaptions(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            call.resolve(["index": viewController.player.currentCaptionsTrack])
        })
    }
    
    @objc func setCurrentCaptions(_ call: CAPPluginCall) {
        guard let index = call.getInt("index") else {
            call.reject("index parameter is required")
            return
        }
        
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            do {
                try viewController.player.setCaptionTrack(index: index)
                call.resolve()
            } catch {
                call.reject("Failed to set captions: \(error.localizedDescription)")
            }
        })
    }
    
    @objc func currentPlaylist(_ call: CAPPluginCall) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                call.reject("No active player")
                return
            }
            
            // Just return an empty array since we can't safely access playlist information
            call.resolve([
                "playlist": []
            ])
        })
    }
}

// Extend JwPlayerPlugin to implement the CallbackHandler protocol
extension JwPlayerPlugin: CallbackHandler {
    func notifyEventListener(_ eventName: String, data: [String: Any]?) {
        print("[JWPlayer] Event: \(eventName), Data: \(String(describing: data))")
        notifyListeners(eventName, data: data)
    }
    
    func onPlayerDismissed() {
        print("[JWPlayer] Player dismissed")
        self.viewController = nil
        self.notifyListeners("playerDismissed", data: nil)
    }
}

// Add AVPictureInPictureControllerDelegate conformance
class CustomPlayerViewController: JWPlayerViewController, JWPlayerViewControllerUIDelegate {
    func playerViewController(_ controller: JWPlayerKit.JWPlayerViewController, sizeChangedFrom oldSize: CGSize, to newSize: CGSize) {
        print("[JWPlayer] Size changed from \(oldSize) to \(newSize)")
        let sizeData: [String: Any] = [
            "oldSize": ["width": oldSize.width, "height": oldSize.height],
            "newSize": ["width": newSize.width, "height": newSize.height]
        ]
        callbackHandler?.notifyEventListener("playerSizeChange", data: sizeData)
    }
    
    func playerViewController(_ controller: JWPlayerKit.JWPlayerViewController, screenTappedAt position: CGPoint) {
        print("[JWPlayer] Screen tapped at: \(position)")
        let positionData: [String: Any] = ["x": position.x, "y": position.y]
        callbackHandler?.notifyEventListener("screenTapped", data: positionData)
    }
    
    
    private var callbackHandler: CallbackHandler?
    private var playerConfig: JWPlayerConfiguration?
    private var closeButton: UIButton! // Custom close button
    
    // Standard init is unavailable
    @available(*, unavailable)
    init() {
        fatalError("init() is unavailable, use init(config:callbackHandler:)")
    }
    
    // Designated initializer
    init(config: JWPlayerConfiguration, callbackHandler: CallbackHandler? = nil) {
        print("[JWPlayer] CustomPlayerViewController init with config")
        self.playerConfig = config
        self.callbackHandler = callbackHandler
        super.init(nibName: nil, bundle: nil)
        
        // Set UI delegate
        self.uiDelegate = self
        print("[JWPlayer] Set self as JWPlayerViewControllerUIDelegate")
        
        // Enable PiP
        self.allowsPictureInPicturePlayback = true
        print("[JWPlayer] allowsPictureInPicturePlayback set to true")
        
        setupFullscreenConfig()
    }
    
    required init?(coder: NSCoder) {
        print("[JWPlayer] CustomPlayerViewController init from coder - Not recommended")
        self.playerConfig = nil
        super.init(coder: coder)
        
        // Set UI delegate
        self.uiDelegate = self
        print("[JWPlayer] Set self as JWPlayerViewControllerUIDelegate (coder init)")
        
        // Enable PiP even if initialized from coder
        self.allowsPictureInPicturePlayback = true
        print("[JWPlayer] allowsPictureInPicturePlayback set to true (coder init)")
        
        setupFullscreenConfig()
    }
    
    private func setupFullscreenConfig() {
        print("[JWPlayer] Setting up fullscreen config")
        // Ensure player is always fullscreen
        modalPresentationStyle = .fullScreen
        
        // Configure the player view to fill the screen
        view.frame = UIScreen.main.bounds
        print("[JWPlayer] Fullscreen config set")
    }
    
    override func viewDidLoad() {
        print("[JWPlayer] viewDidLoad")
        super.viewDidLoad()
        
        // Apply the configuration passed during initialization
        if let config = self.playerConfig {
            print("[JWPlayer] Configuring player from init config")
            player.configurePlayer(with: config)
            print("[JWPlayer] Player configured successfully from init config")
            
            // Attempt to explicitly show PiP button if possible with this SDK
            // Note: JWControlType might require specific strings or might not exist
            // We use a try-catch block to handle potential errors
            do {
                // Try common identifiers for PiP button
//                if let pipControlType = JWControlType(rawValue: "pictureInPictureButton") {
//                    try player.setVisibility(true, for: [pipControlType])
//                    print("[JWPlayer] Attempted to set PiP button visible")
//                } else {
//                    print("[JWPlayer] JWControlType for PiP not found with rawValue 'pictureInPictureButton'")
//                }
            } catch {
                 print("[JWPlayer] Error setting PiP button visibility: \(error.localizedDescription)")
            }
            
        } else {
            print("[JWPlayer] Error: Player configuration is missing in viewDidLoad")
            self.callbackHandler?.notifyEventListener("error", data: ["message": "Player configuration missing"])
        }
        
        // Add the custom close button
        setupCloseButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("[JWPlayer] viewDidAppear")
        super.viewDidAppear(animated)
        
        // Start playback automatically
        print("[JWPlayer] Starting playback")
        player.play()
        print("[JWPlayer] Playback started")
    }
    
    // Setup and add the custom close button
    private func setupCloseButton() {
        closeButton = UIButton(type: .custom)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.6)
        closeButton.layer.cornerRadius = 15 // Smaller corner radius
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Position the button in the top-left corner
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Make sure it's always on top
        closeButton.layer.zPosition = 1000
        // Initially visible, will be updated by delegate method
        closeButton.alpha = 1.0
        print("[JWPlayer] Custom close button added")
    }
    
    // Action for the custom close button
    @objc private func closeButtonTapped() {
        print("[JWPlayer] Custom close button tapped - dismissing player")
        dismiss(animated: true) { [weak self] in
             self?.callbackHandler?.onPlayerDismissed()
        }
    }
    
    // MARK: - JWPlayerViewControllerUIDelegate Method
    
    func playerViewController(_ controller: JWPlayerViewController, controlBarVisibilityChanged isVisible: Bool, frame: CGRect) {
        print("[JWPlayer] Control bar visibility changed: \(isVisible)")
        let targetAlpha: CGFloat = isVisible ? 1.0 : 0.0
        
        // Set alpha directly without animation
        // Ensure closeButton is not nil before accessing
        guard let button = self.closeButton else { return }
        button.alpha = targetAlpha
    }
    
    // MARK: - AVPictureInPictureControllerDelegate Methods (Required Stubs)
    // Implement required methods, even if empty, to satisfy the protocol.
    
    override func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] PiP Will Start")
        // Handle UI changes before PiP starts if needed
    }
    
    override func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] PiP Did Start")
        // Handle UI changes after PiP starts if needed
    }
    
    override func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("[JWPlayer] PiP Failed to Start: \(error.localizedDescription)")
        // Handle error
    }
    
    override func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] PiP Will Stop")
        // Handle UI changes before PiP stops if needed
    }
    
    override func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] PiP Did Stop")
        // Handle UI changes after PiP stops if needed
    }
    
    override func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("[JWPlayer] PiP Restore UI Requested")
        // Restore the player UI. Call completionHandler(true) when done.
        // Since our player is always presented modally, we might just dismiss it or handle it based on app flow.
        // For now, we just complete the handler.
        completionHandler(true)
    }
}
