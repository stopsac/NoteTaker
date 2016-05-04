//
//  NoteTakerViewController.swift
//  NoteTaker
//
//  Created by Bono Kim on 4/5/16.
//  Copyright © 2016 Engene. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData


class NoteTakerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var noteArray: [Note] = [] // core data array
    
    var audioPlayer = AVAudioPlayer()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.tableView.rowHeight = 65.0
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Note")
        self.noteArray = (try! managedObjectContext.executeFetchRequest(fetchRequest)) as! [Note]
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sound = noteArray[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel!.text = sound.name
        
        let font = UIFont(name: "BaskerVille-BoldItalic", size: 26)
        cell.textLabel!.font = font
        
        return cell
    }
    
    func getAudioPlayerFile(file: String, type: String) -> AVAudioPlayer {
        
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
        let url = NSURL.fileURLWithPath(path!)
        var audioPlayer: AVAudioPlayer?
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: url)
            
        } catch let audioPlayerError as NSError {
            
            print("\(audioPlayerError.localizedDescription)")
        }
        
        return audioPlayer!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let sound = noteArray[indexPath.row]
        let documentDirectory = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let pathComponents = [documentDirectory, sound.url!]
        let audioURL = NSURL.fileURLWithPathComponents(pathComponents)!
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: audioURL)
        } catch let fetchError as NSError {
            print("fetch error: \(fetchError.localizedDescription)")
        }
        self.audioPlayer.play()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // add check mark to each row
        
        //let section = indexPath.section
        let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
        
        for row in 0..<numberOfRows {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: indexPath.section)) {
                let image = UIImage(named: "Check Mark2")!
                cell.imageView!.image = image
            }
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedObjectContext = appDelegate.managedObjectContext
            managedObjectContext.deleteObject(noteArray[indexPath.row] as NSManagedObject)
            noteArray.removeAtIndex(indexPath.row)
            
            do {
                
                try managedObjectContext.save()
                
            } catch let deleteError as NSError {
                
                print("delete error: \(deleteError.localizedDescription)")
            }
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            
        }
    }

}
