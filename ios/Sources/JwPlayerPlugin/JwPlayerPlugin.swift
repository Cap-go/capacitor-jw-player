import Foundation
import Capacitor
import JWPlayerKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */

// Protocol for callback handling
protocol CallbackHandler {
    func notifyEventListener(_ eventName: String, data: [String: Any]?)
    func getVideosToPlay() -> VideosToPlay
    func onPlayerDismissed()
}


@objc(JwPlayerPlugin)
public class JwPlayerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "JwPlayerPlugin"
    public let jsName = "JwPlayer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise)
    ]
    private var videosToPlay = VideosToPlay()
    private var viewController: CustomPlayerViewController? = nil
    

    @objc func initialize(_ call: CAPPluginCall) {
        guard let licenseKey = call.getString("licenseKey") else {
            call.reject("licenseKey is required for initialize")
            return
        }
        
        JWPlayerKitLicense.setLicenseKey(licenseKey)

        
        call.resolve()
    }
    
    @objc func play(_ call: CAPPluginCall) {
        guard let mediaUrlStr = call.getString("mediaUrl") else {
            call.reject("mediaUrl is required for initialize")
            return
        }
        
        guard let mediaUrl = URL(string: mediaUrlStr) else {
            call.reject("mediaUrl is required for initialize")
            return
        }
        
        guard let mediaType = call.getString("mediaType") else {
            call.reject("mediaType is required for initialize")
            return
        }
        
        if self.viewController != nil {
            call.reject("the player is already active")
            return
        }
        
        if (!self.videosToPlay.isEmpty) {
            call.reject("videosToPlay is not empty")
            return
        }
        
        switch mediaType {
            case "video":
                videosToPlay.append(.video(url: mediaUrl))
            case "playlist":
                videosToPlay.append(.playlist(loadedUrls: [], isLoaded: false, playlistUrl: mediaUrl))
            default:
                call.reject("Invalid mediaType. Must be either video or playlist")
                return
        }

        
        DispatchQueue.main.async {
            let viewController = CustomPlayerViewController(callbackHandler: self)
            call.resolve()
            self.bridge?.viewController?.present(viewController, animated: false)
        }
    }
}

// Extend JwPlayerPlugin to implement the CallbackHandler protocol
extension JwPlayerPlugin: CallbackHandler {
    func getVideosToPlay() -> VideosToPlay {
        return self.videosToPlay
    }
    
    func notifyEventListener(_ eventName: String, data: [String: Any]?) {
        print("Event: \(eventName), Data: \(String(describing: data))")
    }
    
    func onPlayerDismissed() {
        self.viewController = nil
        // Clear the videos to play by creating a new empty LinkedList
        self.videosToPlay = VideosToPlay()
        // self.notifyListeners("playerDismissed", data: nil)
    }
}

class CustomPlayerViewController: JWPlayerViewController {
    
    private var callbackHandler: CallbackHandler?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(callbackHandler: CallbackHandler? = nil) {
        self.init()
        self.callbackHandler = callbackHandler
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let firstVideo = self.callbackHandler?.getVideosToPlay().first {
            do {
                
                var config: JWPlayerConfiguration? = nil
                switch firstVideo {
                    case .playlist(_, _, let playlistURL):
                         config = try JWPlayerConfigurationBuilder()
                            .playlist(url: playlistURL)
                            .build()
                        break
                    case .video(let url):
                        // Create a JWPlayerItem
                        let item = try JWPlayerItemBuilder()
                            .file(url)
                            .build()
                        config = try JWPlayerConfigurationBuilder()
                            .playlist(items: [item])
                            .build()
                        break
                }
                
                guard let config = config else {
                    print("Unreachable reached (1)")
                    self.callbackHandler?.notifyEventListener("error", data: ["message": "Unreachable reached (1)"])
                    return;
                }
                player.configurePlayer(with: config)
            }
            catch {
                // Handle Error
                print("Error when loading video, no error handling for now")
                callbackHandler?.notifyEventListener("error", data: ["message": "Error loading video: \(error.localizedDescription)"])
            }
        }
    }

    override func jwplayer(_ player: JWPlayer, didPauseWithReason reason: JWPauseReason) {
        super.jwplayer(player, didPauseWithReason: reason)
        callbackHandler?.notifyEventListener("pause", data: ["reason": reason.rawValue])
    }

    // MARK: - JWPlayerDelegate

    
    // Player is ready
    override func jwplayerIsReady(_ player: JWPlayer) {
        super.jwplayerIsReady(player)
        callbackHandler?.notifyEventListener("ready", data: nil)
    }

    // Setup error
    override func jwplayer(_ player: JWPlayer, failedWithSetupError code: UInt, message: String) {
        super.jwplayer(player, failedWithSetupError: code, message: message)
        callbackHandler?.notifyEventListener("setupError", data: ["code": code, "message": message])
    }

    // Error
    override func jwplayer(_ player: JWPlayer, failedWithError code: UInt, message: String) {
        super.jwplayer(player, failedWithError: code, message: message)
        callbackHandler?.notifyEventListener("error", data: ["code": code, "message": message])
    }

    // Warning
    override func jwplayer(_ player: JWPlayer, encounteredWarning code: UInt, message: String) {
        super.jwplayer(player, encounteredWarning: code, message: message)
        callbackHandler?.notifyEventListener("warning", data: ["code": code, "message": message])
    }

    // Ad error
    override func jwplayer(_ player: JWPlayer, encounteredAdError code: UInt, message: String) {
        super.jwplayer(player, encounteredAdError: code, message: message)
        callbackHandler?.notifyEventListener("adError", data: ["code": code, "message": message])
    }

    // Ad warning
    override func jwplayer(_ player: JWPlayer, encounteredAdWarning code: UInt, message: String) {
        super.jwplayer(player, failedWithSetupError: code, message: message)
        callbackHandler?.notifyEventListener("adWarning", data: ["code": code, "message": message])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isBeingDismissed {
            callbackHandler?.onPlayerDismissed()
        }
    }
}
