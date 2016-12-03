//
//  ViewController.swift
//  TaskpaperSerializer
//
//  Created by Adam Lagerhausen on 7/15/16.
//  Copyright © 2016 adam.lagerhausen. All rights reserved.
//

import Cocoa
import BirchOutline

class MainViewController: NSViewController {
    
    @IBOutlet var textField: NSTextField!
    @IBOutlet var timerTextField: NSTextField!
    
    var timer = Timer()
    
    struct ThingsTask {
        var name: String
        var dueDate: String
        var comDate: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //See if there is a saved TaskPaper File path
        let ud = UserDefaults.standard
        let path = ud.string(forKey: "filePath")
        
        if (path != nil) {
            self.setPathName(string: path!)
        }
        
        //Setup repeat sync timer
        self.setTimer()

        //Set timer duration to default or saved duration
        let timerDuration = ud.double(forKey: "timerDuration")
        if (timerDuration != 0.0) {
            self.timerTextField.stringValue = String(timerDuration)
        } else {
            self.timerTextField.stringValue = String(30.0)
        }

        
    }
    
    @IBAction func openFile(sender: AnyObject) {
        
        let openPanel = NSOpenPanel();
        openPanel.allowsMultipleSelection = false;
        openPanel.canChooseDirectories = false;
        openPanel.canCreateDirectories = false;
        openPanel.canChooseFiles = true;
        let i = openPanel.runModal();
        if(i == NSOKButton){
            print(openPanel.url);
            
            self.setPathName(string: openPanel.url!.path)
            
            let fileContent = try? NSString(contentsOfFile: openPanel.url!.path, encoding: String.Encoding.utf8.rawValue)
            
            //print(fileContent)
            
        }
        
    }
    
    func setPathName(string: String) {
        let ud = UserDefaults.standard
        ud.set(string, forKey: "filePath")
        ud.synchronize()
        
        self.textField.stringValue = string
        
    }
        
    @IBAction func sync(_ sender: AnyObject) {
        
        //Sync with Things
        let thingsCon = ThingsController()
        thingsCon.sync()
        
        //Set repeat timer
        setTimer()
        
    }

    func setTimer() {
        
        //Stop timer
        timer.invalidate()
        
        //Get duration from text field
        let timerSecs = TimeInterval(self.timerTextField.stringValue)
        let timerDuration = timerSecs! * 60
        
        //Set timer
        timer = Timer.scheduledTimer(timeInterval: timerDuration, target: self, selector: #selector(MainViewController.sync(_:)), userInfo: nil, repeats: true)
    }
    
    @IBAction func timerTextFieldChanged(sender: AnyObject) {
        
        UserDefaults.standard.set(Double(self.timerTextField.stringValue)!, forKey: "timerDuration")

        self.setTimer()
        
    }

    
}

