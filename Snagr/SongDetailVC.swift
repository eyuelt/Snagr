//
//  SongDetailVC.swift
//  Snagr
//
//  Created by Alexander Hsu on 2/28/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

import UIKit

class SongDetailVC: UIViewController {

    @IBOutlet weak var albumCoverImageView: UIImageView!

    var image : UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        albumCoverImageView.image = image
    }
}
