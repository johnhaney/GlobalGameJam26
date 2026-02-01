//
//  SoundEngine.swift
//  GlobalGameJam26
//
//  Created by John Haney on 2/1/26.
//

import Foundation
import AVKit

enum MusicTrack: String {
    case menu
    case intro
    case world1
    case boss1
    case outro
    case gameover
}

enum SoundEffect: String, CaseIterable {
    case grunt
    case sword
    case swordBlock
    case swordClash
    case thrust
    case swordPickup
    case keyPickup
    case portalTransition
    case arrowAttack
    case teleport
}

class SoundEngine {
    var music: MusicTrack {
        didSet {
            if music != oldValue,
               let oldPlayer = tracks[oldValue] {
                oldPlayer.setVolume(0, fadeDuration: 0.5)
            }
            switch music {
            case .menu:
                break
            case .intro:
                prepareTracks([.intro, .world1])
            case .world1:
                prepareTracks([.world1, .boss1, .gameover])
            case .boss1:
                prepareTracks([.world1, .boss1, .outro])
            case .outro:
                break
            case .gameover:
                break
            }
        }
    }
    
    var tracks: [MusicTrack: AVAudioPlayer] = [:]
    var effects: [SoundEffect: AVAudioPlayer] = [:]

    init() {
        self.music = .menu
        
        prepareTracks([.menu, .intro])
        
        prepareSoundEffects()
    }
    
    func prepareSoundEffects() {
        for effect in SoundEffect.allCases {
            if let url = Bundle.main.url(forResource: "sfx-\(effect.rawValue)", withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                self.effects[effect] = player
            }
        }
    }
    
    func prepareTracks(_ tracks: [MusicTrack]) {
        for track in tracks {
            if self.tracks[track] == nil,
               let url = Bundle.main.url(forResource: "music-\(track.rawValue)", withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                self.tracks[track] = player
            }
        }
    }
    
    func startLooping() {
        tracks[music]?.numberOfLoops = -1
        tracks[music]?.setVolume(1, fadeDuration: 0.5)
        tracks[music]?.play()
    }
    
    func startPlaying() {
        tracks[music]?.numberOfLoops = 0
        tracks[music]?.setVolume(1, fadeDuration: 0.5)
        tracks[music]?.play()
    }
    
    func playSound(_ effect: SoundEffect) {
        guard let player = effects[effect] else {
            return
        }
        
        player.play()
    }
}
