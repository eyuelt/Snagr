//
//  SongHistory.swift
//  Snagr
//
//  Created by Eyuel Tessema on 2/28/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

import Foundation

let defaults = NSUserDefaults.standardUserDefaults()

private struct Constant {
    static let SavedSongsKey = "SavedSongs"
}

func clearSongHistory() {
    defaults.setObject([], forKey: Constant.SavedSongsKey)
}

func addSongToHistory(song: Song) {
    println("Adding song: \(song.propertyList)")
    var songs = defaults.objectForKey(Constant.SavedSongsKey) as? [AnyObject] ?? []
    songs.append(song.propertyList)
    defaults.setObject(songs, forKey: Constant.SavedSongsKey)
    defaults.synchronize()
}

func songsFromHistory() -> [Song] {
    var songPropertyLists = defaults.objectForKey(Constant.SavedSongsKey) as? [AnyObject] ?? []
    var songs = [Song]()
    for propertyList in songPropertyLists {
        songs.append(Song(propertyList: propertyList))
    }
    return songs
}