//
//  LicenseInputController.swift
//  conduit
//
//  Created by Nathan Eidelson on 5/7/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import Foundation

class LicenseInputController : UIViewController {

  @IBOutlet weak var licenseField: UITextField!
  @IBOutlet weak var menuButton: UIButton!
  @IBOutlet weak var continueButton: UIButton!
  var hasChanged = false

  var participantIdentifiers: [String] = []
  
  override func viewDidLoad() {
    
    var sessionKey = NSUserDefaults.standardUserDefaults().stringForKey("session")
    if (sessionKey == nil) {
      performSegueWithIdentifier("to_login", sender: self)
    }
  
    menuButton.addTarget(self.revealViewController(), action:"revealToggle:", forControlEvents:UIControlEvents.TouchUpInside)
    continueButton.backgroundColor = StyleColor.getColor(.Grey, brightness: .Medium)
    
    var timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self,
      selector: "checkTimerFunction", userInfo: nil, repeats: true)
    
    licenseField.becomeFirstResponder()

  }
  
  func presentErrorMessage () {
    var message = "Sorry, we could not find any owners of that car."
    let alertController = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  @IBAction func continueButtonPressed(sender: AnyObject) {
    self.checkCurrentLicense(true, completion: { () -> () in
      self.performSegueWithIdentifier("to_new_message", sender: self)
    })
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "to_new_message" {
      var target: NewMessageViewController = segue.destinationViewController as! NewMessageViewController
      target.participantIdentifiers = self.participantIdentifiers
      target.licensePlate = self.licenseField.text
    }
  }
  
  func checkTimerFunction () {
    self.checkCurrentLicense(false, completion: nil)
  }
  
  @IBAction func licensePlateChanged(sender: AnyObject) {
    self.hasChanged = true
  }

  func checkCurrentLicense (presentErrors: Bool, completion: (()->())?) {
    
    if (!self.hasChanged && !presentErrors) {
      return
    }
    
    NSLog("checkCurrentLicense")
    self.hasChanged = false
    var session = NSUserDefaults().stringForKey("session")!
    
    APIModel.get("cars/\(licenseField.text)/users?session_token=\(session)", parameters: nil) {(result, error) in
    
      if error != nil {
        NSLog("No car found.")
        self.continueButton.backgroundColor = StyleColor.getColor(.Grey, brightness: .Medium)
        if presentErrors {
          self.presentErrorMessage()
        }
        return
      }
      
      var userList = result!["users"]
    
      if userList.count == 0 {
        NSLog("No users for car.")
        self.continueButton.backgroundColor = StyleColor.getColor(.Grey, brightness: .Medium)
        if presentErrors {
          self.presentErrorMessage()
        }
        return
      }
      
      for (var i = 0; i < userList.count; i++) {
        var participantIdentifier = userList[i]["email_address"].stringValue
        self.participantIdentifiers.append(participantIdentifier)
      }
      
      self.continueButton.backgroundColor = StyleColor.getColor(.Primary, brightness: .Medium)
      
      if let block = completion {
        block()
      }
      
    }
  }
  
  
}