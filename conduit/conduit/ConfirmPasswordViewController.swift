//
//  ConfirmPasswordViewController.swift
//  conduit
//
//  Created by Sherman Leung on 4/21/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import UIKit

protocol ConfirmPasswordDelegate {
  func nextSegueAfterConfirm(segueId: String)
}
class ConfirmPasswordViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet var passwordField: UITextField!
  var nextSegueID: String!
  var delegate: ConfirmPasswordDelegate?
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var scrollView: UIScrollView!
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    AnalyticsHelper.trackScreen("ConfirmPassword")
    StyleHelpers.setButtonFont(continueButton)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    passwordField.delegate = self
      
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    
  }
  
  @IBAction func dismissKeyboard(sender: AnyObject) {
    view.endEditing(true)
  }
  
  func keyboardWillShow(notification: NSNotification) {
    var info = notification.userInfo as! [String: NSObject]
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
      
      let animationDuration : NSTimeInterval = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
      
      var contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0,0.0,keyboardSize.height, 0.0)
      scrollView.contentInset = contentInsets
      scrollView.scrollIndicatorInsets = contentInsets
      
      var aRect : CGRect = self.view.frame
      aRect.size.height -= keyboardSize.height
      
      UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
        self.scrollView.scrollRectToVisible(self.continueButton.frame, animated: false)
        }, completion: nil)
      
      self.scrollView.scrollRectToVisible(self.continueButton.frame, animated: true)
      
    }
    
  }
  
  func keyboardWillHide(notification: NSNotification) {
    var contentInsets : UIEdgeInsets  = UIEdgeInsetsZero
    scrollView.contentInset = contentInsets
    scrollView.scrollIndicatorInsets = contentInsets
    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    self.passwordField.becomeFirstResponder()
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
  @IBAction func confirmPassword(sender: AnyObject) {
    var user = User.getUserFromDefaults()
    let params = ["password": passwordField.text, "email_address": user?.emailAddress]
    println(params)
    APIModel.post("sessions", parameters: params) { (result, error) -> () in
      if (error == nil) {
        self.delegate?.nextSegueAfterConfirm(self.nextSegueID)
      } else {
        let alertController = UIAlertController(title: "", message:
          "Incorrect Password!", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
      }
    }
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    passwordField.resignFirstResponder()
    confirmPassword(passwordField)
    return true
  }

}
