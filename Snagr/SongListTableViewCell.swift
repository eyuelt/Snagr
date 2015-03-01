//
//  SongListTableViewCell.swift
//  Snagr
//
//  Created by Alexander Hsu on 2/28/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

import UIKit

class SongListTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var accessTimeLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
