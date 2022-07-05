//
//  ViewController.swift
//  anAudioUnitDemo
//
//  Created by August on 2022/7/5.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {
    
    var io: AudioUnit?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        WZAUKit.setupAudioSessionForCategory(.playAndRecord)
    }

    @IBAction func startRecord(_ sender: Any) {
        
        WZAUKit.openFile()
        
        WZAUKit.share.setupAudioUnit(&io)
        
        AudioOutputUnitStart(io!)
        
    }
    
    @IBAction func stopRecord(_ sender: Any) {
    }
    
    
    @IBAction func startPlaying(_ sender: Any) {
    }
    
    
    @IBAction func stopPlaying(_ sender: Any) {
    }
}

