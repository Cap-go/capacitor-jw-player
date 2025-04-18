//
//  VideosToPlay.swift
//  Pods
//
//  Created by WcaleNieWolny on 18/04/2025.
//

/// Type alias for a LinkedList of MediaNodeType, representing a queue of videos to play
public typealias VideosToPlay = LinkedList<MediaNodeType>

/// An enum to represent the type of media node
public enum MediaNodeType {
    /// A playlist that contains multiple video URLs
    case playlist(loadedUrls: [URL], isLoaded: Bool, playlistUrl: URL)
    /// A single video URL
    case video(url: URL)
}

/// A specialized node for the VideosToPlay linked list
public class MediaNode: Node<MediaNodeType> {
    /// The type of the media node
    public var nodeType: MediaNodeType {
        return value
    }
    
    /// Whether this node is a playlist
    public var isPlaylist: Bool {
        switch value {
        case .playlist:
            return true
        case .video:
            return false
        }
    }
    
    /// Whether this node is a video
    public var isVideo: Bool {
        switch value {
        case .video:
            return true
        case .playlist:
            return false
        }
    }
    
    /// Create a new playlist node
    public static func createPlaylist(playlistUrl: URL) -> MediaNode {
        return MediaNode(value: .playlist(loadedUrls: [], isLoaded: false, playlistUrl: playlistUrl))
    }
    
    /// Create a new video node
    public static func createVideo(url: URL) -> MediaNode {
        return MediaNode(value: .video(url: url))
    }
}

