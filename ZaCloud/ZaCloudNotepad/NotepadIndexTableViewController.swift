//
//  NotepadIndexTableViewController.swift
//  ZaCloudNotepad
//
//  Created by Zachary Kanzhe Liu on 2016-01-24.
//  Copyright © 2016 Zachary Kanzhe Liu. All rights reserved.
//

import UIKit
import SystemConfiguration
import CoreSpotlight
import MobileCoreServices


class NotepadIndexTableViewController: UITableViewController{
    
    @IBOutlet weak var refresh: UIBarButtonItem!

   
    @IBOutlet var indexTableView: UITableView!
    let stringToDate = DateTimeFromString()
    let noteListName = "noteList.plist"
    let syncDateLocalCopy = "syncRecords.plist"
    let deletionRecordsCopy = "deletionRecords.plist"
    let updateRecordsCopy = "updateRecords.plist"
    let newNoteRecordsCopy = "newNoteRecords.plist"

    var noteIndex = 0
    
    var author :String!
    
    var newNotesRecords = [newNoteRecord]()
    var updateRecords = [UpdateRecord]()
    var deletionRecords = [DeletionRecord]()
    var notes = [Note]()
    var syncDate:NSDate!
    var timer:NSTimer!

    var semaphore:dispatch_semaphore_t
    var syncGroup: dispatch_group_t
    var queue: dispatch_queue_t
    
    required init(coder aDecoder: NSCoder) {
        self.semaphore = dispatch_semaphore_create(3)
        self.syncGroup = dispatch_group_create()
        self.queue = dispatch_queue_create("dispatch_queue_serial", DISPATCH_QUEUE_SERIAL)
        super.init(coder: aDecoder)!
    }
    
    lazy var refreshController: UIRefreshControl = {
       let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NotepadIndexTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        return refreshControl
    }()
    
    //this only initializes the screen
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.addSubview(self.refreshController)
        //print("number of notes: ",notes.count)
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(NotepadIndexTableViewController.synchronization), userInfo: nil, repeats: true)
        loadData()
        
    }
    
    
    //this function refresh the screen every time it gets back
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
       
        //print("number of notes in index: ",notes.count)
        self.tableView.reloadData()
        
    }
    
    func loadData(){
        

        
        loadDefaultUserFromLocal()
        //author = "zach"
        //syncUpdatedNotesFromServer(NSDate())
        //***********************   load from local plist   *************************************
        //local save location
        loadNotesFromLocal()
   
        //***********************   Load complete   *************************************
        synchronization()
        
      //**************** read complete ****************
        self.tableView.performSelectorOnMainThread(Selector("reloadData"), withObject: nil, waitUntilDone: true)
        
    }
    
    
    
    
    func handleRefresh(refreshControl:UIRefreshControl){
        print("refresh!!!")
        
        
        //dispatch_time_t group = dispatch_group_create()
            //self.synchronization()
        
        
        //var globalQueueDefault = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)
        
//        dispatch_sync(globalQueueDefault){
            self.synchronization()
//
//        }
         //       dispatch_async(dispatch_get_main_queue()){
          //          self.freshingDone(refreshControl)
          //      }
        
         dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        self.freshingDone(refreshControl)
        }
        
    
    
    func freshingDone(refreshControl:UIRefreshControl){
        //sleep(1)
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
        
    }
    
    
    //****************************  delete function  *********************************************
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete){

            
            if isConnectedToNetwork() {
                let lock = SendLocking()
                if lock.send(author,createDate: notes[indexPath.row].createDate){//save it to the server
                if deleteDataOnPHP(indexPath.row){
                    self.notes.removeAtIndex(indexPath.row)
                    self.navigationController?.popViewControllerAnimated(true)
                    saveNotesToLocal()
                    }
                }else{
                    let alert = UIAlertView(title: "Deletion failed", message: "Cannot delete this note without lock.", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
            //self.tableView.reloadData()
                
            }else{
                let alert = UIAlertView(title: "No Internet Connection", message: "Cannot delete note without internet.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
            //*************************** Change the local copy  ******************************************
           self.tableView.reloadData()
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
     }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       // print("number of notes: ",notes.count)
       return notes.count
        
    }

    //setup the cell
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let note = notes[indexPath.row]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "US/Michigan")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localTime = dateFormatter.stringFromDate(note.lastModified)
        
        
        
        cell.textLabel?.text = note.title as String
        cell.detailTextLabel?.text = localTime
        

        return cell
    }
    

    @IBAction func refreshOnClick(sender: AnyObject) {
        

        
        
    }
    
   
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "back" {
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    
    if segue.identifier == "addNote" || segue.identifier == "openNote"{
            let noteVC = segue.destinationViewController as! NotepadTableViewController
            noteVC.notes = self.notes
    
        if segue.identifier == "addNote"{
           noteVC.noteOnShow = Note()
        }else if segue.identifier == "openNote"{
           // noteVC.noteDict = noteDict
            
            let indexPath = self.tableView.indexPathForSelectedRow
            noteVC.noteOnShow = notes[indexPath!.row]
            noteVC.noteIndex = indexPath!.row
            noteIndex = indexPath!.row
            noteVC.isExist = true
            
        }
    }
    
    }

    @IBAction func unwindSegue(unwindSegue: UIStoryboardSegue) {
        //author = "Zach"
        let notepad = unwindSegue.sourceViewController as? NotepadTableViewController
        let noteText = notepad?.noteTextField.text
        let noteTitle = notepad?.titleTextField.text
        
        var note = Note()
        
        if  noteText != "" || noteTitle != ""{//make sure that no empty note be saved in
            if !notepad!.isExist {//if does not exist, append the array
                note = Note(title: noteTitle!, noteText: noteText!, author: author)
                let currentDate = NSDate()
                note.lastModified = currentDate
                note.updateDevice = UIDevice.currentDevice().identifierForVendor!.UUIDString
               // note.locked = false
                note.lockingTime = currentDate
                notes.append(note)
                
                saveNotesToLocal()
                if(isConnectedToNetwork()){     //if network is avaliable, save it to network
                    postNewNoteToPHP(note)
                    //saveLastSyncDateToLocal()
                }else{                          //else, save the record to local, wait for network avaliable
                    var newNoterecord = newNoteRecord(name: note.author,createDate: note.createDate)
                    newNotesRecords.append(newNoterecord)
                    saveNewNoteRecordsToLocal()
                }
                self.navigationController?.popViewControllerAnimated(true)
                
            }else{//
                //update to memory
                let backupNote = notes[noteIndex].note
                let backupTitle = notes[noteIndex].title
                let backupDate = notes[noteIndex].lastModified
                
                notes[noteIndex].note = noteText
                notes[noteIndex].title = noteTitle
                let currentDate = NSDate()
                notes[noteIndex].lastModified = currentDate
               //update to local copy
                let locker = SendLocking()
                locker.unlock(author, createDate: notes[noteIndex].createDate)
                
               
                
                if isConnectedToNetwork() {
                        let lock = SendLocking()
                        if lock.send(author, createDate: notes[noteIndex].createDate){
                            updateToPHP(noteIndex)
                        }else{//restore from backup and pop up alarm
                            notes[noteIndex].note = backupNote
                            notes[noteIndex].title = backupTitle
                            notes[noteIndex].lastModified = backupDate
                            
                            let alert = UIAlertView(title: "Update failed", message: "Cannot update this note without lock.", delegate: nil, cancelButtonTitle: "OK")
                            alert.show()
                        }
                        
                    
                    //saveLastSyncDateToLocal()
                }else{  //networks isn't avaliable, then save to local record
                    var updateRecord = UpdateRecord(name: notes[noteIndex].author, createDate: notes[noteIndex].createDate, updateDate: notes[noteIndex].lastModified)
                    
                    var i=0
                    var exist = false
                    for i=0; i<updateRecords.count;i++ {
                        if updateRecords[i].createDate.description == updateRecord.createDate.description{
                            updateRecords[i].updateDate = updateRecord.updateDate
                            exist = true
                            break
                        }
                    }
                    if !exist {
                        updateRecords.append(updateRecord)
                    }
                    
                    saveUpdateRecordsToLocal()
                    
                    
                }
                saveNotesToLocal()
            }
        }

        
    }
    //***********************   synchronization   *************************************
    //***********************   synchronization   *************************************
    //***********************   synchronization   *************************************
    //***********************   synchronization   *************************************
    //***********************   synchronization   *************************************
    //***********************   synchronization   *************************************
    
    func synchronization(){
        
        //var semaphore = dispatch_semaphore_create(1)
        //dispatch_semaphore_signal(semaphore)
        loadLastSyncDateFromLocal()
        //var syncGroup = dispatch_group_create()
        var queue = dispatch_queue_create("dispatch_queue_serial", DISPATCH_QUEUE_SERIAL)
        
        if self.syncDate == self.stringToDate.convertStringtoNSDate("1990-01-01 00:00:00") {
            
           // dispatch_group_enter(self.syncGroup)
                self.syncNewNotesFromServer(self.syncDate)
           
           // dispatch_semaphore_signal(self.semaphore)
            

        }else{
            
            //**************** sync deletion **************************************
            
           
                self.syncDeletionRecordFromServer(self.syncDate)
           
//
            self.saveDeletionRecordsToLocal()  //save the notes
        
        //**************** sync update **************************************
            
            if self.updateRecords.count != 0 {   //sync update to server
                let lock = SendLocking()
                var i=0
                for i=0;i<self.updateRecords.count;i++ {
                  
                    let index = self.getNoteIndex(self.updateRecords[i].createDate)
                    if index   != -1 {
                        if lock.send(author, createDate: notes[index].createDate){
                            self.updateToPHP(index)
                            lock.unlock(author, createDate: notes[index].createDate)
                        }
                       
                    }
                 
                    //self.updateRecords.removeAtIndex(i)
                }
                self.updateRecords.removeAll()
            }
            self.saveUpdateRecordsToLocal()
        
           
            self.syncUpdatedNotesFromServer(self.syncDate)    //sync update from server
           
        //**************** sync new notes **************************************
            self.loadNewNoteRecordsFromLocal()
            //print("number of new notes: ", self.newNotesRecords.count)
            //if self.newNotesRecords.count != 0 {
                var i=0
                for i=0;i<self.newNotesRecords.count;i++ {
                  
                    let index = self.getNoteIndex(self.newNotesRecords[i].createDate)
                    if index   != -1 {
                        self.postNewNoteToPHP(self.notes[index])
                    }
                 
                    //self.newNotesRecords.removeAtIndex(i)
                }
                self.newNotesRecords.removeAll()
            //}
            self.saveNewNoteRecordsToLocal()
        
           //self.tableView.performSelectorOnMainThread(#selector(self.syncNewNotesFromServer(_:)), withObject: self.syncDate, waitUntilDone: true)
            self.syncNewNotesFromServer(self.syncDate) //sync new notes from server
            
            print("end of sync")
            // dispatch_semaphore_signal(self.semaphore)

        }
//
        
        
      //  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
       // dispatch_sync(queue){
    //  sleep(1)
       //            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
        dispatch_group_wait(self.syncGroup,DISPATCH_TIME_FOREVER)
        print("wait is over ")
        dispatch_async(dispatch_get_main_queue()){
            
            
            self.tableView.reloadData()
            self.saveNotesToLocal()
            self.saveLastSyncDateToLocal()
        }
        
        //}
        
        
       // dispatch_semaphore_signal(self.semaphore)
        
    }

    //  ******************* helper methods ******************************
    //  ******************* helper methods ******************************
    //  ******************* helper methods ******************************
    //  ******************* helper methods ******************************
    //  ******************* helper methods ******************************
    func deleteFromNotes(deletetion:DeletionRecord){
        var i=0
        for i=0;i<notes.count;i++ {
             print("#: ",i, "note: ", self.notes[i].createDate.description, "record: ", deletetion.createDate.description, "is equal: ", (notes[i].createDate.description == deletetion.createDate.description))
            if notes[i].createDate.description == deletetion.createDate.description {
                notes.removeAtIndex(i)
            }
        }
       
    }
    
   // && notes[i].lastModified.compare(deletetion.deleteDate) == NSComparisonResult.OrderedAscending
    
    func getNoteIndex(createDate:NSDate)->Int{
        var i=0
        for i=0;i<notes.count;i++ {
           
            if notes[i].createDate.description == createDate.description {
                return i
            }
        }
        
        return -1
    }
    //  ******************* helper methods ******************************
    //  ******************* helper methods ******************************
    
    
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    //***********************   NETWORK AVALIABILITY!!!!!!!!!!!!!!!!   *************************************
    func isConnectedToNetwork()->Bool{
        
        var Status:Bool = false
        let url = NSURL(string: "http://54.191.76.174/start.html")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: NSURLResponse?
        do{
            var data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response) as NSData?
        } catch {
            print("Something wrong in is ConnectedToNetwork")
        }
    
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
            
        }
        else
        {
            
            let alert = UIAlertView(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
        
        return Status
    }
    
    
    
    
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DATA MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    
    //***********************   load from local plist   *************************************
    func loadNotesFromLocal(){
       // print("load notes from local")
        let noteName = author + noteListName
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let noteListPath = (basePath as NSString).stringByAppendingPathComponent(noteName)
        if NSFileManager.defaultManager().fileExistsAtPath(noteListPath){
            guard let notes = NSKeyedUnarchiver.unarchiveObjectWithFile(noteListPath) as? [Note]
                else {
                    print("decoding failure")
                    return }
            
            
            self.notes = notes
            
            //print(notes.count)
        }
    }
//***********************   ***************************   *************************************
    //******************************    Save notes to local copy *********************************
    func saveNotesToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
       // print("save notes to local")
        //local save location
        let noteName = author + noteListName
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        let basePath = path[0]
        
        let noteListPath = (basePath as NSString).stringByAppendingPathComponent(noteName)
        
        NSKeyedArchiver.archiveRootObject(notes, toFile: noteListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
    }
    //************************************** Save to local Complete *******************************************
    
    
    //***********************   DEFAULT USER MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   DEFAULT USER MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   DEFAULT USER MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   DEFAULT USER MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   DEFAULT USER MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    func saveDefaultUserToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
        
        //local save location
        let copyName = "default.plist"
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        let basePath = path[0]
        
        let noteListPath = (basePath as NSString).stringByAppendingPathComponent(copyName)
        
        
        let defaultUser = User(name:"zach")
        
        
        
        NSKeyedArchiver.archiveRootObject(defaultUser, toFile: noteListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
    }
    //************************************** Save DATE to local Complete *******************************************
    
    
    //************************************** load DATE from local  *******************************************
    func loadDefaultUserFromLocal(){
        // author = "zach"
        //***********************   load from local plist   *************************************
        //local save location
        let copyName = "default.plist"
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let syncDataPath = (basePath as NSString).stringByAppendingPathComponent(copyName)
        if NSFileManager.defaultManager().fileExistsAtPath(syncDataPath){
            guard let defaultUser = NSKeyedUnarchiver.unarchiveObjectWithFile(syncDataPath) as? User
                else {
                    print("decoding failure")
                    
                    return
            }
            self.author = defaultUser.username as! String
            
            //print("loading test: ",(notes.count))
        }else{
            return
        }
        
        
    }

    
    
    

    //***********************   LOCAL SYNC DATE MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL SYNC DATE MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL SYNC DATE MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL SYNC DATE MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL SYNC DATE MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    
    //************************************** Save DATE to local Complete *******************************************
    func saveLastSyncDateToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
        //print("save last sync date to local")
        //local save location
        let copyName = author + syncDateLocalCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        let basePath = path[0]
        
        let noteListPath = (basePath as NSString).stringByAppendingPathComponent(copyName)
        
        
        let syncDate = SyncDate(name: author, syncDate: NSDate())
        self.syncDate = syncDate.syncDate
        
        
        NSKeyedArchiver.archiveRootObject(syncDate, toFile: noteListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
        
        print("save sync date test: "+syncDate.syncDate.description)
        
        
    }
    //************************************** Save DATE to local Complete *******************************************
    

    //************************************** load DATE from local  *******************************************
    func loadLastSyncDateFromLocal(){
       // author = "zach"
        //***********************   load from local plist   *************************************
        //local save location
        let syncDateName = author + syncDateLocalCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let syncDatePath = (basePath as NSString).stringByAppendingPathComponent(syncDateName)
        if NSFileManager.defaultManager().fileExistsAtPath(syncDatePath){
            guard let syncDate = NSKeyedUnarchiver.unarchiveObjectWithFile(syncDatePath) as? SyncDate
                else {
                    print("decoding failure")
                    //yyyy-MM-dd HH:mm:ss SSSS
                    self.syncDate = stringToDate.convertStringtoNSDate("1990-01-01 00:00:00")
                    return
            }
            self.syncDate = syncDate.syncDate
            
            //print("loading test: ",(notes.count))
        }else{
            self.syncDate = stringToDate.convertStringtoNSDate("1990-01-01 00:00:00")
        }
        print("read sync date test: "+syncDate.description)
        
    }
    //************************************** load DATE Complete *******************************************
    
    //***********************   LOCAL DELETION RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DELETION RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DELETION RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DELETION RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL DELETION RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    
    //***********************   load from local plist   *************************************
    func loadDeleteRecordsFromLocal(){
       // print("load delete records from local")
        let listName = author + deletionRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        if NSFileManager.defaultManager().fileExistsAtPath(recordsListPath){
            guard let records = NSKeyedUnarchiver.unarchiveObjectWithFile(recordsListPath) as? [DeletionRecord]
                else {
                    print("decoding failure")
                    return }
            
            
            self.deletionRecords = records
        }
    }

    //***********************   ***************************   *************************************
    //******************************    Save deletion records to local copy *********************************
    func saveDeletionRecordsToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
        //print("save deletetion records to local")
        //local save location
        let listName = author + deletionRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        
        NSKeyedArchiver.archiveRootObject(deletionRecords, toFile: recordsListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
    }
//***********************   ***************************   *************************************
    
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************  
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************  
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************  
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************  
     //***********************   LOCAL UPDATE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************  
    //***********************   load from local plist   *************************************
    func loadUpdateRecordsFromLocal(){
       // print("load update records from local")
        let listName = author + updateRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        if NSFileManager.defaultManager().fileExistsAtPath(recordsListPath){
            guard let records = NSKeyedUnarchiver.unarchiveObjectWithFile(recordsListPath) as? [UpdateRecord]
                else {
                    print("decoding failure")
                    return }
            
            
            self.updateRecords = records
        }
    }
    
    //***********************   ***************************   *************************************
    //******************************    Save update records to local copy *********************************
    func saveUpdateRecordsToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
       // print("save update records to local")
        //local save location
        let listName = author + updateRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        
        NSKeyedArchiver.archiveRootObject(updateRecords, toFile: recordsListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    //***********************   LOCAL NEW NOTE RECORDS MANAGEMENT!!!!!!!!!!!!!!!!   *************************************
    
    func loadNewNoteRecordsFromLocal(){
        //print("load new note records from local")
        let listName = author + newNoteRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        if NSFileManager.defaultManager().fileExistsAtPath(recordsListPath){
            guard let records = NSKeyedUnarchiver.unarchiveObjectWithFile(recordsListPath) as? [newNoteRecord]
                else {
                    print("decoding failure")
                    return }
            
            
            self.newNotesRecords = records
            //print("number of new note: " , records.count)
            
        }
    }
    
    //***********************   ***************************   *************************************
    //******************************    Save new note records to local copy *********************************
    func saveNewNoteRecordsToLocal() {
        //self.navigationController?.popViewControllerAnimated(true)
       // print("save new note records to local")
        //local save location
        let listName = author + newNoteRecordsCopy
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let basePath = path[0]
        let recordsListPath = (basePath as NSString).stringByAppendingPathComponent(listName)
        
        NSKeyedArchiver.archiveRootObject(newNotesRecords, toFile: recordsListPath)
        
        self.navigationController?.popViewControllerAnimated(true)
       //print("save new note record, number: " , newNotesRecords.count)
    }
    
    //****************************************************************************************************
    
    //********************************* Post new note to PHP *********************************************
    //********************************* Post new note to PHP *********************************************
    //********************************* Post new note to PHP *********************************************
    //********************************* Post new note to PHP *********************************************
    //********************************* Post new note to PHP *********************************************
    //********************************* Post new note to PHP *********************************************
    
    func postNewNoteToPHP(note:Note){
       // print("post new note to php")
        //********************* post it to web server **************************
        let myUrl = NSURL(string: "http://54.191.76.174/insert.php")
        let request = NSMutableURLRequest(URL:myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "title=\(note.title)&note=\(note.note)&author=\(note.author)&createDate=\((note.createDate.description as NSString).substringToIndex(19))&lastModified=\((note.lastModified.description as NSString).substringToIndex(19))&updateDevice=\(UIDevice.currentDevice().identifierForVendor!.UUIDString)&isDeleted=0"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
            
            //print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            //dispatch_semaphore_signal(self.semaphore)
           // self.tableView.reloadData()
           
            
        }
        task.resume()
        // dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        //********************* post complete **********************************
    }
    //*********************************************************************************
    
    
    
    
    //************************* update notes to PHP web server*****************************************************
    //************************* update notes to PHP web server*****************************************************
    //************************* update notes to PHP web server*****************************************************
    //************************* update notes to PHP web server*****************************************************
    //************************* update notes to PHP web serve *****************************************************
    //************************* update notes to PHP web server*****************************************************
    
    func updateToPHP(noteIndex:Int) -> Bool{
        print("update to php")
        let lock = SendLocking()
        if !lock.send(author, createDate: self.notes[noteIndex].createDate){
            return false
        }
        
        
        let myUrl = NSURL(string: "http://54.191.76.174/update.php")
        let request = NSMutableURLRequest(URL:myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "title=\(notes[noteIndex].title)&note=\(notes[noteIndex].note)&author=\(notes[noteIndex].author)&lastModified=\((notes[noteIndex].lastModified.description as NSString).substringToIndex(19))&updateDevice=\(UIDevice.currentDevice().identifierForVendor!.UUIDString)&locked=\(0)&createDate=\((notes[noteIndex].createDate.description as NSString).substringToIndex(19))"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
            
            //print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            dispatch_semaphore_signal(self.semaphore)
            
           //self.tableView.reloadData()
        }
        task.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return true
        //************************* update complete    *************************
    }
    
    
    
    //********************  delete note at php side *********************************************************
    //********************  delete note at php side *********************************************************
    //********************  delete note at php side *********************************************************
    //********************  delete note at php side *********************************************************
    //********************  delete note at php side *********************************************************
    //********************  delete note at php side *********************************************************
    func deleteDataOnPHP(indexPath:Int) -> Bool{
        print("delete data on php")
        let lock = SendLocking()
        if !lock.send(author, createDate: self.notes[indexPath].createDate){
            return false
        }
        
        
        let myUrl = NSURL(string: "http://54.191.76.174/deletion.php")
        let request = NSMutableURLRequest(URL:myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "deleteDate=\((NSDate().description as NSString).substringToIndex(19))&author=\(notes[indexPath].author)&createDate=\((notes[indexPath].createDate.description as NSString).substringToIndex(19))&updateDevice=\(UIDevice.currentDevice().identifierForVendor!.UUIDString)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
       // print(postString)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
            
            //print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            dispatch_semaphore_signal(self.semaphore)
            self.tableView.reloadData()
            
        }
        
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return true
    }
    
//    func deleteDataOnPHPbyRecord(record:DeletionRecord){
//        
//        let myUrl = NSURL(string: "http://54.191.76.174/deletion.php")
//        let request = NSMutableURLRequest(URL:myUrl!)
//        request.HTTPMethod = "POST"
//        
//        let postString = "deleteDate=\((NSDate().description as NSString).substringToIndex(19))&author=\(record.username)&createDate=\((record.createDate.description as NSString).substringToIndex(19))&updateDevice=\(UIDevice.currentDevice().identifierForVendor!.UUIDString)"
//        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
//        print(postString)
//        
//        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
//            data, response, error in
//            
//            if error != nil {
//                print("error=\(error)")
//                return
//            }
//            
//            
//            //print("response = \(response)")
//            
//            // Print out response body
//            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//            print("responseString = \(responseString)")
//            dispatch_semaphore_signal(self.semaphore)
//            
//            
//            
//        }
//        task.resume()
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
//    }
//    
    
    
     //***********************   ***************************   *************************************
    //***********************   ***************************   *************************************
    
    //******    read later updated notes from php JSON for a paticular person  ****************************
    //******    read later updated notes from php JSON for a paticular person  ****************************
    //******    read later updated notes from php JSON for a paticular person  ****************************
    //******    read later updated notes from php JSON for a paticular person  ****************************
    //******    read later updated notes from php JSON for a paticular person  ****************************
    //******    read later updated notes from php JSON for a paticular person  ****************************
        //************************************************************************
    func syncUpdatedNotesFromServer(syncDate:NSDate) {
        print("sync update notes from server")
        let urlString = "http://54.191.76.174/SyncUpdateFromServer.php?author="+author+"&lastSyncDate="+(syncDate.description as NSString).substringToIndex(19)+"&updateDevice="+UIDevice.currentDevice().identifierForVendor!.UUIDString
        let temp = urlString.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)

        let url = NSURL(string: temp)
        //var i:Int
        //let request = NSMutableURLRequest(URL:url!)
        
        //print("sync update from server: "+temp)
        //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        
        dispatch_group_enter(self.syncGroup)
       // dispatch_group_async(syncGroup, dispatch_get_main_queue()){
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
            {(data:NSData?, resonse:NSURLResponse?, error:NSError?)->Void in
                do {
                    
                    if(data == nil){
                        print("nil")
                        return
                    }
                    
                    let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! [NSDictionary]
                    
                    print("num of updated note: ", jsonDictionary.count)
                    var i:Int
                    var newNote:Note
                    //print(jsonDictionary.count)
                    for i=0; i<jsonDictionary.count; i++ {
                        //print(jsonDictionary[i]["title"])
                        newNote = Note()
                        newNote.title = jsonDictionary[i]["title"] as! NSString
                        newNote.note = jsonDictionary[i]["note"] as! NSString
                        newNote.author = jsonDictionary[i]["author"] as! NSString
                        if jsonDictionary[i]["createDate"] != nil{
                            newNote.createDate = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["createDate"] as! String)
                        }
                        if jsonDictionary[i]["lastModified"] != nil{
                            newNote.lastModified = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["lastModified"] as! String)
                        }
                        if jsonDictionary[i]["lockingTime"] as! String != ""{
                            newNote.lockingTime = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["lockingTime"] as! String)
                        }
                        
                       // if (jsonDictionary[i]["locked"] as! String == "1") {
                       // newNote.locked = true
                       // }else{
                        //newNote.locked = false
                         //}
                        
                        newNote.updateDevice = jsonDictionary[i]["updateDevice"] as! String
                        
                        var index = self.getNoteIndex(newNote.createDate)
                        
                        if index != -1 {
                            self.notes[index]=newNote
                        }else{
                            self.notes.append(newNote)
                        }
                    }
                    
                }catch{
                    print("oops")
                }
                self.tableView.reloadData()
                self.saveNotesToLocal()
                dispatch_group_leave(self.syncGroup)
             //   dispatch_semaphore_signal(self.semaphore)
                
        }).resume()
      
       // dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        print("update complete")
    }
    
    //******    read new notes from php JSON for a paticular person  ****************************
    //******    read new notes from php JSON for a paticular person  ****************************
    //******    read new notes from php JSON for a paticular person  ****************************
    //******    read new notes from php JSON for a paticular person  ****************************
    //******    read new notes from php JSON for a paticular person  ****************************
    //******    read new notes from php JSON for a paticular person  ****************************
    func syncNewNotesFromServer(syncDate:NSDate) {
        print("sync new notes from server")
        let urlString = "http://54.191.76.174/newNotes.php?author="+author+"&lastSyncDate="+(syncDate.description as NSString).substringToIndex(19)+"&updateDevice="+UIDevice.currentDevice().identifierForVendor!.UUIDString
        let temp = urlString.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        //let temp = urlTmp.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())! as String
        let url = NSURL(string: temp)
        //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        
        dispatch_group_enter(self.syncGroup)
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
            {(data:NSData?, resonse:NSURLResponse?, error:NSError?)->Void in
                do {
                    
                    if(data == nil){
                        print("nil")
                        return
                    }

                    
                     let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! [NSDictionary]
                    
                    var i:Int
                    var newNote:Note
                    print("num of new note: ",jsonDictionary.count)
                    for i=0; i<jsonDictionary.count; i++ {
                        //print(jsonDictionary[i]["title"])
                        newNote = Note()
                        newNote.title = jsonDictionary[i]["title"] as! NSString
                        newNote.note = jsonDictionary[i]["note"] as! NSString
                        newNote.author = jsonDictionary[i]["author"] as! NSString
                        if jsonDictionary[i]["createDate"] as! String != ""{
                            newNote.createDate = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["createDate"] as! String)
                        }
                        if jsonDictionary[i]["lastModified"] as! String != ""{
                            newNote.lastModified = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["lastModified"] as! String)
                        }
                        if jsonDictionary[i]["lockingTime"] as! String != ""{
                            newNote.lockingTime = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["lockingTime"] as! String)
                        }
                        
                        // if (jsonDictionary[i]["locked"] as! String == "1") {
                        //newNote.locked = true
                        //}else{
                        //newNote.locked = false
                        // }
                        
                        newNote.updateDevice = jsonDictionary[i]["updateDevice"] as! String
                        var index = self.getNoteIndex(newNote.createDate)
                        
                        if index != -1 {
                            self.notes[index] = newNote
                        }else{
                            self.notes.append(newNote)
                        }
                        
                    }
                   
                }catch{
                    print("oops")
                }
                dispatch_group_leave(self.syncGroup)
               self.tableView.reloadData()
                self.saveNotesToLocal()
            //    dispatch_semaphore_signal(self.semaphore)
        }).resume()
       // }
       
      //   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
         print("newnote complete")
    }

    
        //********************  delete notes from php complete *************************************
        
        //************************************* sync deletion record from server *****************************
        //************************************* sync deletion record from server *****************************
        //************************************* sync deletion record from server *****************************
        //************************************* sync deletion record from server *****************************
        //************************************* sync deletion record from server *****************************
        //************************************* sync deletion record from server *****************************
        func syncDeletionRecordFromServer(syncDate:NSDate){
            print("sync deletion record from server")
            let urlString = "http://54.191.76.174/syncDeletionRecords.php?author="+author+"&lastSyncDate="+(syncDate.description as NSString).substringToIndex(19)+"&updateDevice="+(UIDevice.currentDevice().identifierForVendor!.UUIDString)
            let temp = urlString.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            let url = NSURL(string: temp)
            //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
            
            dispatch_group_enter(self.syncGroup)
           NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
                {(data:NSData?, resonse:NSURLResponse?, error:NSError?)->Void in
                    do {
                       // print("Delete record?")
                        
                        if(data == nil){
                            print("nil")
                            return
                        }
                        //print("Delete record?")
                        
                        let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! [NSDictionary]
                        
                        var i:Int
                        var newRecord:DeletionRecord!
                        if self.deletionRecords.count == 0 {
                            self.deletionRecords = [DeletionRecord]()
                        }
                        //print(jsonDictionary.count)
                        for i=0; i<jsonDictionary.count; i++ {
                            //print(jsonDictionary[i]["title"])
                            newRecord = DeletionRecord()
                            newRecord.username = jsonDictionary[i]["author"] as! NSString
                            
                            if jsonDictionary[i]["createDate"] as! String != ""{
                                newRecord.createDate = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["createDate"] as! String)
                            }
                            if jsonDictionary[i]["lastModified"] as!String != ""{
                                newRecord.deleteDate = self.stringToDate.convertStringtoNSDate(jsonDictionary[i]["lastModified"] as! String)
                            }
                            
                            //print("Delete record?")
                            var i=0
                            var recordExisted = false
                            for (i=0;i<self.deletionRecords.count;i++){

                            }
                            
                                self.deletionRecords.append(newRecord)
                            
                        }
                        
                        print("num of delete: ", self.deletionRecords.count)
                        if self.deletionRecords.count != 0 {
                            var i=0
                            for i=0;i<self.deletionRecords.count;i++ {
                                self.deleteFromNotes(self.deletionRecords[i])
                                
                            }
                            self.deletionRecords.removeAll()
                        }
                        
                       // dispatch_semaphore_signal(self.semaphore)
                    }catch{
                        print("oops")
                    }
                 dispatch_group_leave(self.syncGroup)
               // dispatch_semaphore_signal(self.semaphore)
                self.tableView.reloadData()
                self.saveNotesToLocal()
                }).resume()
        
           // dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
           print("Deletion complete")
    }
    
        //****************************************************************************************************

//    func addToSpotLight(notes:[Note]){
//         let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
//        
//        
//    }
    
}
