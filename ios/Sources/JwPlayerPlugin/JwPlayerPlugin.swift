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
    func onPlayerDismissed(isPiPDismissal: Bool) // Track dismissal source
    func rePresentPlayerRequested() // Request plugin to re-present
}

@objc(JwPlayerPlugin)
public class JwPlayerPlugin: CAPPlugin, CAPBridgedPlugin {
    private let pluginVersion: String = "8.0.6"
    // public class JwPlayerPlugin: CAPPlugin, CAPBridgedPlugin, GCKLoggerDelegate {
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
        CAPPluginMethod(name: "currentPlaylist", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resume", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise)
    ]
    private var viewController: CustomPlayerViewController?

    override public func load() {
        // Configure the audio session when the plugin loads
        setupAudioSession()
        // print("[JWPlayer] Plugin loaded. Note: Chromecast is initialized in AppDelegate.")
        // initializeChromecast()
        super.load()
    }

    private func setupAudioSession() {
        print("[JWPlayer] Setting up AVAudioSession")
        do {
            // Configure audio session for playback and PiP
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("[JWPlayer] AVAudioSession configured successfully for playback")
        } catch {
            print("[JWPlayer] Error setting up AVAudioSession: \(error.localizedDescription)")
        }
    }

    // private func initializeChromecast() {
    //     print("[ChromecastDebug] Starting Chromecast initialization")
    //     let kReceiverAppID = "CC1AD845" // Custom App ID for Chromecast
    //     let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
    //     let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
    //     options.physicalVolumeButtonsWillControlDeviceVolume = true
    //     options.disableDiscoveryAutostart = false
    //     print("[ChromecastDebug] Setting custom options for Chromecast")
    //     do {
    //         GCKCastContext.setSharedInstanceWith(options)
    //         print("[ChromecastDebug] Chromecast context initialized with App ID: \(kReceiverAppID)")
    //     } catch {
    //         print("[ChromecastDebug] Error initializing Chromecast context: \(error.localizedDescription)")
    //     }

    //     let filter = GCKLoggerFilter.init()
    //     filter.minimumLevel = .verbose
    //     GCKLogger.sharedInstance().filter = filter
    //     GCKLogger.sharedInstance().delegate = self
    //     print("[ChromecastDebug] Logger initialized")
    // }

    // public func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
    //     print(function + " - " + message)
    // }

    // @objc func initialize(_ call: CAPPluginCall) {
    //     print("[JWPlayer] initialize called")
    //     guard let licenseKey = call.getString("licenseKey") else {
    //         print("[JWPlayer] Error: licenseKey is missing")
    //         call.reject("licenseKey is required for initialize")
    //         return
    //     }

    //     print("[JWPlayer] Setting license key")
    //     JWPlayerKitLicense.setLicenseKey(licenseKey)
    //     print("[JWPlayer] License key set successfully")

    //     call.resolve()
    // }

    @objc func play(_ call: CAPPluginCall) {
        print("[JWPlayer] play called with options: \(call.options)")
        guard let mediaUrlStr = call.getString("mediaUrl") else {
            print("[JWPlayer] Error: mediaUrl is missing")
            call.reject("mediaUrl is required for initialize")
            return
        }

        guard let mediaUrl = URL(string: mediaUrlStr) else {
            print("[JWPlayer] Error: mediaUrl is invalid URL: \(mediaUrlStr)")
            call.reject("mediaUrl is invalid URL: \(mediaUrlStr)")
            return
        }

        guard let mediaType = call.getString("mediaType") else {
            print("[JWPlayer] Error: mediaType is missing")
            call.reject("mediaType is required for initialize")
            return
        }

        let autostart = call.getBool("autostart") ?? false

        if self.viewController != nil {
            print("[JWPlayer] Error: player is already active")
            call.reject("the player is already active")
            return
        }

        print("[JWPlayer] Media type: \(mediaType), URL: \(mediaUrl)")

        // Create configuration directly
        var config: JWPlayerConfiguration?
        do {
            switch mediaType {
            case "video":
                print("[JWPlayer] Creating video configuration")
                let item = try JWPlayerItemBuilder()
                    .file(mediaUrl)
                    .build()
                config = try JWPlayerConfigurationBuilder()
                    .playlist(items: [item])
                    .autostart(autostart)
                    .build()
            case "playlist":
                print("[JWPlayer] Creating playlist configuration")
                config = try JWPlayerConfigurationBuilder()
                    .playlist(url: mediaUrl)
                    .autostart(autostart)
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
            // Ensure any previous instance is fully dismissed first
            if self.viewController != nil {
                print("[JWPlayer] Warning: Play called while a player VC might still exist. Forcing cleanup.")
                self.viewController = nil
            }

            let viewController = CustomPlayerViewController(config: finalConfig, callbackHandler: self)
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .crossDissolve
            self.viewController = viewController // Keep strong reference
            print("[JWPlayer] Resolving play call")
            call.resolve()
            print("[JWPlayer] Presenting view controller over current context")
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

    @objc func resume(_ call: CAPPluginCall) {
        print("[JWPlayer] resume called")
        DispatchQueue.main.async(execute: DispatchWorkItem {
            guard let viewController = self.viewController else {
                print("[JWPlayer] Error: Cannot resume, no active player")
                call.reject("No active player to resume")
                return
            }

            print("[JWPlayer] Resuming playback")
            viewController.player.play()
            call.resolve()
            print("[JWPlayer] Play command sent to player")
        })
    }
}

// Extend JwPlayerPlugin to implement the CallbackHandler protocol
extension JwPlayerPlugin: CallbackHandler {
    func notifyEventListener(_ eventName: String, data: [String: Any]?) {
        print("[JWPlayer] Event: \(eventName), Data: \(String(describing: data))")
        notifyListeners(eventName, data: data)
    }

    func onPlayerDismissed(isPiPDismissal: Bool) {
        print("[JWPlayer] Player dismissed callback. Was PiP dismissal: \(isPiPDismissal)")
        // Only nil out the reference if it wasn't a dismissal for starting PiP
        if !isPiPDismissal {
            print("[JWPlayer] Manual dismissal detected, releasing VC reference.")
            self.viewController = nil
            self.notifyListeners("playerDismissed", data: nil)
        } else {
            print("[JWPlayer] PiP dismissal detected, keeping VC reference for potential restore.")
            // Optionally notify JS that PiP started if needed
            self.notifyListeners("pipStarted", data: nil)
        }
    }

    func rePresentPlayerRequested() {
        print("[JWPlayer] Re-present player requested")
        guard let vc = self.viewController else {
            print("[JWPlayer] Error: Cannot re-present, view controller is nil.")
            return
        }
        guard let bridgeVC = self.bridge?.viewController else {
            print("[JWPlayer] Error: Cannot re-present, bridge view controller is nil.")
            return
        }

        // Ensure it's not already being presented or presenting something else
        if vc.isBeingPresented || vc.presentingViewController != nil || bridgeVC.presentedViewController != nil {
            print("[JWPlayer] Warning: Cannot re-present, presentation context busy.")
            return
        }

        DispatchQueue.main.async {
            print("[JWPlayer] Re-presenting player view controller")
            bridgeVC.present(vc, animated: true)
        }
    }

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve(["version": self.pluginVersion])
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
    private var timeUpdateTimer: Timer? // Timer for periodic time updates

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
        self.forceFullScreenOnLandscape = false
        self.forceLandscapeOnFullScreen = false
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

            // JWPlayerViewController already has self as delegates
            // We are just implementing the delegate methods
        } else {
            print("[JWPlayer] Error: Player configuration is missing in viewDidLoad")
            self.callbackHandler?.notifyEventListener("error", data: ["message": "Player configuration missing"])
        }

        // Add the custom close button
        setupCloseButton()

        // Start time update timer after player is ready
        startTimeUpdateTimer()
    }

    // Start a timer to emit time updates periodically
    private func startTimeUpdateTimer() {
        // Cancel any existing timer
        timeUpdateTimer?.invalidate()

        // Create a new timer that fires every second
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.player.getState() == .playing {
                let position = self.player.time.position
                let duration = self.player.time.duration

                let timeData: [String: Any] = [
                    "position": position,
                    "duration": duration
                ]

                self.callbackHandler?.notifyEventListener("time", data: timeData)
            }
        }
    }

    // Stop the time update timer
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        print("[JWPlayer] viewDidAppear")
        super.viewDidAppear(animated)
        print("[JWPlayer] Button exists \(view.viewWithTag(2136) !== nil)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop the time update timer when view disappears
        stopTimeUpdateTimer()

        // Only trigger the dismissal callback if it's a manual dismissal
        if self.isBeingDismissed || self.isMovingFromParent {
            print("[JWPlayer] Manual dismissal detected in viewWillDisappear")
            callbackHandler?.onPlayerDismissed(isPiPDismissal: false)
        }
    }

    // Setup and add the custom close button
    private func setupCloseButton() {
        closeButton = UIButton(type: .custom)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.6)
        closeButton.layer.cornerRadius = 15 // Smaller corner radius
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .allTouchEvents)
        closeButton.tag = 2136

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

        self.setVisibility(.hidden, for: [.fullscreenButton])
        print("[JWPlayer] Fullscreen button hidden")
    }

    // Action for the custom close button
    @objc private func closeButtonTapped() {
        print("[JWPlayer] Custom close button tapped - dismissing player manually")
        self.dismiss(animated: true) { [weak self] in
            // Use the new callback signature
            self?.callbackHandler?.onPlayerDismissed(isPiPDismissal: false)
        }
    }

    // MARK: - JWPlayerDelegate Methods

    override func jwplayerIsReady(_ player: JWPlayer) {
        super.jwplayerIsReady(player)
        print("[JWPlayer] Player is ready")
        callbackHandler?.notifyEventListener("ready", data: nil)
    }

    override func jwplayer(_ player: JWPlayer, failedWithError code: UInt, message: String) {
        super.jwplayer(player, failedWithError: code, message: message)
        print("[JWPlayer] Error: \(message), code: \(code)")
        let errorData: [String: Any] = [
            "message": message,
            "code": code
        ]
        callbackHandler?.notifyEventListener("error", data: errorData)
    }

    override func jwplayer(_ player: JWPlayer, failedWithSetupError code: UInt, message: String) {
        super.jwplayer(player, failedWithSetupError: code, message: message)
        print("[JWPlayer] Setup error: \(message), code: \(code)")
        let errorData: [String: Any] = [
            "message": message,
            "code": code
        ]
        callbackHandler?.notifyEventListener("error", data: errorData)
    }

    // MARK: - JWPlayerStateDelegate Methods

    override func jwplayer(_ player: JWPlayer, isPlayingWithReason reason: JWPlayReason) {
        super.jwplayer(player, isPlayingWithReason: reason)
        print("[JWPlayer] Playing with reason: \(reason)")
        callbackHandler?.notifyEventListener("play", data: ["reason": reason.rawValue])
    }

    override func jwplayer(_ player: JWPlayer, didPauseWithReason reason: JWPauseReason) {
        super.jwplayer(player, didPauseWithReason: reason)
        print("[JWPlayer] Paused with reason: \(reason)")
        callbackHandler?.notifyEventListener("pause", data: ["reason": reason.rawValue])
    }

    override func jwplayerContentDidComplete(_ player: JWPlayer) {
        super.jwplayerContentDidComplete(player)
        print("[JWPlayer] Content completed")
        callbackHandler?.notifyEventListener("complete", data: nil)
    }

    override func jwplayer(_ player: JWPlayer, seekedFrom oldPosition: TimeInterval, to newPosition: TimeInterval) {
        super.jwplayer(player, seekedFrom: oldPosition, to: newPosition)
        print("[JWPlayer] Seeked from \(oldPosition) to \(newPosition)")
        let seekData: [String: Any] = [
            "position": oldPosition,
            "offset": newPosition
        ]
        callbackHandler?.notifyEventListener("seek", data: seekData)
    }

    override func jwplayer(_ player: JWPlayer, didLoadPlaylistItem item: JWPlayerItem, at index: UInt) {
        super.jwplayer(player, didLoadPlaylistItem: item, at: index)
        print("[JWPlayer] Playlist item loaded at index: \(index)")
        var itemData: [String: Any] = ["index": index]

        // Add title if available
        if let title = item.title, !title.isEmpty {
            itemData["title"] = title
        }

        callbackHandler?.notifyEventListener("playlistItem", data: itemData)
    }

    override func jwplayerPlaylistHasCompleted(_ player: JWPlayer) {
        super.jwplayerPlaylistHasCompleted(player)
        print("[JWPlayer] Playlist completed")
        callbackHandler?.notifyEventListener("playlistComplete", data: nil)
    }

    // MARK: - JWPlayerViewControllerUIDelegate Method

    func playerViewController(_ controller: JWPlayerViewController, controlBarVisibilityChanged isVisible: Bool, frame: CGRect) {
        print("[JWPlayer] Control bar visibility changed: \(isVisible)")
        let targetAlpha: CGFloat = isVisible ? 1.0 : 0.0

        // Set alpha directly without animation
        // Ensure closeButton is not nil before accessing
        guard let button = self.closeButton else { return }
        button.alpha = targetAlpha

        // Emit controlsChanged event to match other platforms
        callbackHandler?.notifyEventListener("controlsChanged", data: ["visible": isVisible])
    }

    // MARK: - AVPictureInPictureControllerDelegate Methods

    override func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] Delegate: PiP Will Start")
        if #available(iOS 14.2, *) {
            pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = true
            print("[JWPlayer] Set canStartPictureInPictureAutomaticallyFromInline to true. It's current value:  \(pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline)")
        }
        super.pictureInPictureControllerWillStartPictureInPicture(pictureInPictureController)
    }

    override func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] Delegate: PiP Did Start")
        super.pictureInPictureControllerDidStartPictureInPicture(pictureInPictureController)
        callbackHandler?.notifyEventListener("pipStarted", data: ["isInPictureInPictureMode": true])
    }

    override func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("[JWPlayer] Delegate: PiP Failed to Start: \(error.localizedDescription)")
        super.pictureInPictureController(pictureInPictureController, failedToStartPictureInPictureWithError: error)
        callbackHandler?.notifyEventListener("error", data: ["message": "Failed to start PiP: \(error.localizedDescription)"])
    }

    override func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] Delegate: PiP Will Stop")
        super.pictureInPictureControllerWillStopPictureInPicture(pictureInPictureController)
    }

    override func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[JWPlayer] Delegate: PiP Did Stop")
        super.pictureInPictureControllerDidStopPictureInPicture(pictureInPictureController)
        callbackHandler?.notifyEventListener("pipStopped", data: ["isInPictureInPictureMode": false])
    }

    override func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Here I will REMOVE the button to close and readd it
        if let closeButton = self.closeButton {
            closeButton.removeFromSuperview()
            self.setupCloseButton()
        }

        // MARK: - IMPORTANT-
        // Make sure to call the super method when you have restored the UI, it is important to notify the system of this.
        super.pictureInPictureController(pictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }

    // MARK: - JWCastDelegate
    // Optionally, override the following methods to receive and respond to events when casting.
    // Always call the superclass's method when overriding these methods.

    // Called when a new casting device comes online.
    override func castController(_ controller: JWCastController, devicesAvailable devices: [JWCastingDevice]) {
        super.castController(controller, devicesAvailable: devices)
        print("[JWCastDelegate]: \(devices.count) became available: \(devices)")
    }

    // Called when a successful connection to a casting device is made.
    override func castController(_ controller: JWCastController, connectedTo device: JWCastingDevice) {
        super.castController(controller, connectedTo: device)
        print("[JWCastDelegate]: Connected to device: \(device.identifier)")
    }

    // Called when the casting device disconnects.
    override func castController(_ controller: JWCastController, disconnectedWithError error: Error?) {
        super.castController(controller, disconnectedWithError: error)

        if let error {
            print("[JWCastDelegate]: Casting disconnected from device with error: \"\(error.localizedDescription)\"")
        } else {
            print("[JWCastDelegate]: Casting disconnected from device successfully.")
        }
    }

    // Called when the connected casting device is temporarily disconnected. Video resumes on the mobile device until connection resumes.
    override func castController(_ controller: JWCastController, connectionSuspendedWithDevice device: JWCastingDevice) {
        super.castController(controller, connectionSuspendedWithDevice: device)
        print("[JWCastDelegate]: Connection suspended with device: \(device.identifier)")
    }

    // Called after connection is reestablished following a temporary disconnection. Video resumes on the casting device.
    override func castController(_ controller: JWCastController, connectionRecoveredWithDevice device: JWCastingDevice) {
        super.castController(controller, connectionRecoveredWithDevice: device)
        print("[JWCastDelegate]: Connection recovered with device: \(device.identifier)")
    }

    // Called when an attempt to connect to a casting device is unsuccessful.
    override func castController(_ controller: JWCastController, connectionFailedWithError error: Error) {
        super.castController(controller, connectionFailedWithError: error)
        print("[JWCastDelegate]: Connection failed with error: \(error.localizedDescription)")
    }

    // Called when casting session begins.
    override func castController(_ controller: JWCastController, castingBeganWithDevice device: JWCastingDevice) {
        super.castController(controller, castingBeganWithDevice: device)
        print("[JWCastDelegate]: Casting began with device: \(device.identifier)")
    }

    // Called when an attempt to cast to a casting device is unsuccessful.
    override func castController(_ controller: JWCastController, castingFailedWithError error: Error) {
        super.castController(controller, castingFailedWithError: error)
        print("[JWCastDelegate]: Casting failed with error: \(error.localizedDescription)")
    }

    // Called when a casting session ends.
    override func castController(_ controller: JWCastController, castingEndedWithError error: Error?) {
        super.castController(controller, castingEndedWithError: error)

        if let error {
            print("[JWCastDelegate]: Casting ended with error: \"\(error.localizedDescription)\"")
        } else {
            print("[JWCastDelegate]: Casting ended successfully.")
        }
    }
}
