//
//  NowPlayingViewController.swift
//  Something
//
//  Created by Eyuel Tessema on 2/28/15.
//  Copyright (c) 2015 Eyuel Tessema. All rights reserved.
//

import UIKit
import AVFoundation

class NowPlayingViewController: UIViewController, AVAudioPlayerDelegate {
    
    let songs: [Song] = [
        Song(title: "Chandelier", artist: "Sia"),
        Song(title: "Ghost", artist: "Ella Henderson"),
        Song(title: "Uma", artist: "Panama Wedding"),
        Song(title: "Elastic Heart", artist: "Sia"),
    ]

    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumArt: UIImageView!
    
    var player: AVAudioPlayer! = nil {
        didSet {
            player.delegate = self
        }
    }

    var currentSong: Int = 0 {
        didSet {
            //if currentSong == songs.count { currentSong = 0 } //loop. we might not want to do this
            if currentSong < songs.count {
                let song = songs[currentSong]
                song.timePlayed = NSDate()
                songLabel.text = song.title!
                artistLabel.text = song.artist!
                albumArt.image = UIImage(named: "Images/" + song.title! + ".png")
                let songPath = NSBundle.mainBundle().pathForResource("Audio/" + song.title!, ofType:"m4a")
                let songUrl = NSURL(fileURLWithPath: songPath!)
                player = AVAudioPlayer(contentsOfURL: songUrl, error: nil)
                player.play()
            } else {
                currentSong = songs.count - 1
            }
        }
    }
    
    var pingPlayer: AVAudioPlayer! = nil {
        didSet {
            pingPlayer.prepareToPlay()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SpeechRecognizer().setup()
        
        clearSongHistory()
        let pingPath = NSBundle.mainBundle().pathForResource("Audio/ping", ofType:"mp3")
        pingPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: pingPath!), error: nil)
        currentSong = 0
        
        //notification
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(7 * NSEC_PER_SEC)), dispatch_get_main_queue()) { [unowned self] in
            self.dimMusicAndDo() {
                self.pingPlayer.play()
                self.songSnagged()
            }
        }
    }
    
    func dimMusicAndDo(handler: () -> Void) {
        let savedVolume = self.player.volume
        self.player.volume /= 3
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Float(NSEC_PER_SEC))), dispatch_get_main_queue()) { [unowned self] in
            handler()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Float(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.player.volume = savedVolume
            }
        }
    }
    
    func songSnagged() {
        let msg = "Snagged a song from someone nearby!"
        let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .ActionSheet)
        presentViewController(alertController, animated: true) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    @IBAction func tap(sender: UITapGestureRecognizer) {
        let song = songs[currentSong]
        song.status = "Skipped"
        if nextSong() {
            addSongToHistory(song)
        }
    }
    
    //skips to the next song and returns whether or not it successfully changed
    func nextSong() -> Bool {
        let saved = currentSong
        currentSong++
        return currentSong != saved
    }
    
    @IBAction func twoFingerTap(sender: UITapGestureRecognizer) {
        if player.playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    //MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        let song = songs[currentSong]
        song.status = "Completed"
        addSongToHistory(song)
        nextSong();
    }
}

