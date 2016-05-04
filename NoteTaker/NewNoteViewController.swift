//
//  NewNoteViewController.swift
//  NoteTaker
//
//  Created by Bono Kim on 4/6/16.
//  Copyright © 2016 Engene. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class NewNoteViewController: UIViewController {
    
    
    required init?(coder aDecoder: NSCoder) {
        
        let baseString: String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        self.audioURL = NSUUID().UUIDString + ".m4a"
        let pathComponents = [baseString, self.audioURL]
        let audioNSURL = NSURL.fileURLWithPathComponents(pathComponents)!
        let session = AVAudioSession.sharedInstance()
        
        let recordSettings = [
        
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 2 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        
        ]
        
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            self.audioRecorder = try AVAudioRecorder(URL: audioNSURL, settings: recordSettings)
            
        } catch let initError as NSError {
            
            print("Initialization error: \(initError.localizedDescription)")
        }
        
        self.audioRecorder.meteringEnabled = true
        self.audioRecorder.prepareToRecord()
        
        super.init(coder: aDecoder)        
        
    }
    
    
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var recordButton: UIButton!

    @IBOutlet weak var recordTimeLabel: UILabel!
    
    @IBOutlet weak var peakImageView: UIImageView!
    @IBOutlet weak var averageImageView: UIImageView!
    
    // global properties and methods
    var audioRecorder: AVAudioRecorder!
    var audioURL: String
    var audioPlayer = AVAudioPlayer()
    
    let recordTimeInterval: NSTimeInterval = 0.5

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        recordButton.layer.shadowOpacity = 1.0
        recordButton.layer.shadowOffset = CGSize(width: 5.0, height: 4.0)
        recordButton.layer.shadowRadius = 5.0
        recordButton.layer.shadowColor = UIColor.blackColor().CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: AnyObject) {
        
        if noteTextField.text == "" {
            let alert = UIAlertController(title: "Warning", message: "You must enter a name", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedObjectContext = appDelegate.managedObjectContext
            let noteEntity = NSEntityDescription.entityForName("Note", inManagedObjectContext: managedObjectContext)
            let managedObject = Note(entity: noteEntity!, insertIntoManagedObjectContext: managedObjectContext)
            
            managedObject.name = noteTextField.text!
            managedObject.url = audioURL
            
            do {
                
                try managedObjectContext.save()
                
            } catch let saveError as NSError {
                
                print("Saving error: \(saveError.localizedDescription)")
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)

            
        }
        
    }
    
    @IBAction func record(sender: AnyObject) {
        
        let microphoneRecordImage = UIImage(named: "pinkbuttonRecord.png")
        recordButton.setImage(microphoneRecordImage, forState: .Normal)
        
        recordButton.layer.shadowOpacity = 0.9
        recordButton.layer.shadowOffset = CGSize(width: 3.0, height: 2.0)
        recordButton.layer.shadowRadius = 5.0
        recordButton.layer.shadowColor = UIColor.blackColor().CGColor
        
        if audioRecorder.recording {
            
            audioRecorder.stop()
            let microphoneStopImage = UIImage(named: "whitebuttonNormal.png")
            recordButton.setImage(microphoneStopImage, forState: .Normal)
            
        } else {
            
            let recordingSession = AVAudioSession.sharedInstance()
            
            do {
                try recordingSession.setActive(true)
                audioRecorder.record()
                
            } catch let recordingError as NSError {
                
                print("recording error: \(recordingError.localizedDescription)")
            }
        }
    }
    
    
    @IBAction func touchDownRecord(sender: AnyObject) {
        
        self.audioPlayer = getAudioPlayerFile("beep1", type: "mp3")
        self.audioPlayer.play()
        
        let recordingTimer = NSTimer.scheduledTimerWithTimeInterval(recordTimeInterval, target: self, selector: #selector(self.updateAudioMeter(_:)), userInfo: nil, repeats: true)
        recordingTimer.fire()
        
        recordButton.layer.shadowOpacity = 0.9
        recordButton.layer.shadowOffset = CGSize(width: -2.0, height: -2.0)
        recordButton.layer.shadowRadius = 1.0
        recordButton.layer.shadowColor = UIColor.blackColor().CGColor
    }
    
    func updateAudioMeter(timer: NSTimer) {
        
        
        if audioRecorder.recording {
            
            let dFormat = "%02d"
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime % 60)
            let recordingTimeString = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
            recordTimeLabel.text = recordingTimeString
            audioRecorder.updateMeters()
            let averageAudio = audioRecorder.averagePowerForChannel(0) * -1
            let peakAudio = audioRecorder.peakPowerForChannel(0) * -1
            let progressViewAtAverage = Int(averageAudio)
            let progressViewAtPeak = Int(peakAudio)
            
            averagePeakRadial(progressViewAtAverage, peak: progressViewAtPeak)
            
            
        } else if !audioRecorder.recording {
            
            averageImageView.image = UIImage(named: "average0radial.png")
            peakImageView.image = UIImage(named: "peak0radial.png")
            crossFadeTransition()

        }
    }
    
    
    // A function that grabs any audio file path and creates an audio player
    
    func getAudioPlayerFile(file: String, type: String) -> AVAudioPlayer {
        
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
        let url = NSURL.fileURLWithPath(path!)
        var audioPlayer: AVAudioPlayer?
        
        do {
            
            try audioPlayer = AVAudioPlayer(contentsOfURL: url)
            
        } catch let audioPlayerError as NSError {
            
            print("audio player initializing error: \(audioPlayerError.localizedDescription)")
        }
        return audioPlayer!
    }
    
    func averagePeakRadial(average: Int, peak: Int) {
        
        switch average {
            
        case average:
            averageImageView.image = UIImage(named: "average\(String(average))radial.png")
            crossFadeTransition()
        
        default:
            averageImageView.image = UIImage(named: "average10radial.png")
            crossFadeTransition()
        
        }
        
        switch peak {
            
        case peak:
            peakImageView.image = UIImage(named: "peak\(String(peak))radial.png")
            crossFadeTransition()
            
        default: peakImageView.image = UIImage(named: "peak10radial.png")
            crossFadeTransition()
            
        }
        
    }
    
    func crossFadeTransition() {
        
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        view.layer.addAnimation(transition, forKey: nil)
    }
   
}
