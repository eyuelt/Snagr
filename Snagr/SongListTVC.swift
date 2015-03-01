//
//  SongListTVC.swift
//  Snagr
//
//  Created by Alexander Hsu on 2/28/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

import UIKit

class SongListTVC: UITableViewController {

    var songs: [Song] {
        return songsFromHistory()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    private struct Storyboard {
        static let CellReuseIdentifier = "SongCell"
        static let SegueIdentifier = "ShowDetail"
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return songs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as SongListTableViewCell

        // Configure the cell...

        let song = songs[indexPath.row]
        cell.titleLabel.text = song.title!
        cell.artistLabel.text = song.artist!
        cell.statusLabel.text = song.status!
        cell.accessTimeLabel.text = ""
        cell.locationLabel.text = ""
        cell.thumbnailImageView.image = UIImage(named: "Images/" + song.title! + ".png")
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get indexPath for the selected cell
        let indexPath : NSIndexPath? = tableView?.indexPathForCell(sender as SongListTableViewCell)
        
        if segue.identifier == Storyboard.SegueIdentifier {
            
            // Set up destination view controller
            if let songDetailVC = segue.destinationViewController as? SongDetailVC {
                if let index = indexPath?.row {
                    songDetailVC.image = UIImage(named: "thumbnail0.png")
                }
            }
        }
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
