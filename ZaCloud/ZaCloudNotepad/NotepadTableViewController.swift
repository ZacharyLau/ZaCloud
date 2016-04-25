//
//  NotepadTableViewController.swift
//  ZaCloudNotepad
//
//  Created by Zachary Kanzhe Liu on 2016-01-24.
//  Copyright © 2016 Zachary Kanzhe Liu. All rights reserved.
//

import UIKit

class NotepadTableViewController: UITableViewController{
    
    @IBOutlet weak var noteTextField: UITextView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var isExist = false
    var timer:NSTimer!
    
    //plist part will be replaced by remote connection in the near future
   // let noteListName = "noteList.plist"
   
    //var noteDict:NSMutableDictionary!
    //[title, note, lastModified, createDate, author]
    var notes = [Note]()
    var locker = SendLocking()
    var isLocked = false
    //=========================================================================
    var noteOnShow:Note!
    var noteIndex = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if noteOnShow != nil {
            isLocked = locker.send(noteOnShow.author as String, createDate: noteOnShow.createDate)
        }
                
            if noteOnShow.title != nil {
                titleTextField.text = noteOnShow.title as String
            }
            if noteOnShow.note != nil {
            noteTextField.text = noteOnShow.note as String
        }
        //print("number of notes in VC2: ",notes.count)
                   
       // }
        
        self.navigationItem.rightBarButtonItem = saveButton
        saveButton.enabled = false
        if (isLocked && isExist) || !isExist{
            saveButton.enabled = true
            timer = NSTimer.scheduledTimerWithTimeInterval(110, target: self, selector: "lockTheNote", userInfo: nil, repeats: true)
            
        }else{
            saveButton.enabled = false
        }

        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        
        let locker = SendLocking()
        if (isExist && isLocked) || !isExist{
            locker.unlock(noteOnShow.author as String, createDate: noteOnShow.createDate)
            timer.invalidate()
        }
        self.dismissViewControllerAnimated(true, completion: {});

        
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        //self.dismissViewControllerAnimated(true, completion: {});
        //timer.invalidate()
    }
    
    func lockTheNote(){
        isLocked = locker.send(noteOnShow.author as String, createDate: noteOnShow.createDate)
    }
    
    func getNote() -> Note {
        //from the plist file. It will be changed in the near future
        var note = Note()
        
        if  noteTextField.text != nil || titleTextField.text != nil{//make sure that no empty note be saved in
            note = Note(title: titleTextField.text!, noteText: noteTextField.text, author: "Me")
            let currentDate = NSDate()
            note.lastModified = currentDate
            
        }
        
        return note
        
    }
    
     func saveNote() {
        //self.navigationController?.popViewControllerAnimated(true)
        
        //local save location
        
        //let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        //let basePath = path[0]
        
        //let noteListPath = (basePath as NSString).stringByAppendingPathComponent(noteListName)
        
        
        
        if (noteTextField.text != nil || titleTextField.text != nil){       //if we change the note that exists
            
            //notes[noteIndex] = getNote()
            
            notes.append(getNote())
            
            noteIndex = notes.count - 1//replace getNote()
            
            print("number of notes saved in notepad: ",notes.count)

            
        }
        //dont save empty note
        
        
        
        //check the dictionary exists or not
        
       // if noteDict == nil{
            
      //      noteDict = NSMutableDictionary()
            
      //  }
        
        
        
        
        
        //noteDict["notes"] = notes
        
        
        
        //noteDict.writeToFile(noteListPath, atomically: true)
        
        
        
        
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
   
}
