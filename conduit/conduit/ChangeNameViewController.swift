//
//  ChangeNameViewController.swift
//  conduit
//
//  Created by Sherman Leung on 4/29/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import UIKit

class ChangeNameViewController: UIViewController {

  @IBOutlet var lastNameField: UITextField!
  @IBOutlet var firstNameField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
  @IBAction func saveChanges(sender: AnyObject) {
    var sessionToken = NSUserDefaults().stringForKey("session")
    var user = NSUserDefaults().objectForKey("user") as! User
    var params = user.present()
    params.updateValue(firstNameField.text, forKey: "first_name")
    params.updateValue(lastNameField.text, forKey: "last_name")
    params.updateValue(sessionToken!, forKey: "session_token")
    user.update { (result, error) -> () in
      let alertController = UIAlertController(title: "", message:
        "Your name has been updated!", preferredStyle: UIAlertControllerStyle.Alert)
      alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
      
      self.presentViewController(alertController, animated: true, completion: nil)
    }
  }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}