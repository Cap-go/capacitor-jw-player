import Foundation
import Capacitor

@objc public class JwPlayer: NSObject {
    @objc public func initialize(_ call: CAPPluginCall) -> String {
        return "initialized"
    }
    
    @objc public func play(_ call: CAPPluginCall) -> String {
        return "playing"
    }
    
    @objc public func pause(_ call: CAPPluginCall) -> String {
        return "paused"
    }
    
    @objc public func stop(_ call: CAPPluginCall) -> String {
        return "stopped"
    }
    
    @objc public func seekTo(_ call: CAPPluginCall) -> String {
        return "seeked"
    }
}
