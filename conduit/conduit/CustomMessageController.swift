//
//  CustomMessageController.swift
//  conduit
//
//  Created by Nisha Masharani on 4/1/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import Foundation
import UIKit

class CustomMessageController : UIViewController {
  
  @IBOutlet weak var licenseTextField: UITextField!
  @IBOutlet weak var messageTextField: UITextField!
  @IBOutlet weak var buttonPosition: NSLayoutConstraint!
  var licensePlate : String! // Only used to pass variables from previous VC
  
  @IBOutlet var keyboardDismisser: UITapGestureRecognizer!
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    AnalyticsHelper.trackScreen("CustomMessage")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if licensePlate == "" {
      licenseTextField.becomeFirstResponder()
      
    } else {
      messageTextField.becomeFirstResponder()
      licenseTextField.text = licensePlate
    }
    self.view.backgroundColor = StyleColor.getColor(.Grey, brightness: .Light)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    
    licenseTextField.autocorrectionType = UITextAutocorrectionType.No
    messageTextField.autocorrectionType = UITextAutocorrectionType.No
    keyboardDismisser.enabled = true
  }
  
  func keyboardWillShow(notification: NSNotification) {
    keyboardDismisser.enabled = true
    var info = notification.userInfo as! [String: NSObject]
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
      self.buttonPosition.constant = keyboardSize.height
    }
  }
  
  func keyboardWillHide(notification: NSNotification) {
    self.buttonPosition.constant = 0
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  
  @IBAction func dismissKeyboard(sender: AnyObject) {
    self.view.endEditing(true)
    keyboardDismisser.enabled = false
  }
  
  // Send a custom message 
  // TODO: add API calls
  @IBAction func sendCustomMessage(sender: AnyObject) {
    // TODO: do we want to trim just whitespace or whitespace AND newlines?
    var message = messageTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    
    // if we have an empty message, do nothing.
    if message == "" {
      return
    }
    
    if let n = self.navigationController?.viewControllers?.count {
      if let previousViewController = self.navigationController?.viewControllers[n-2] as! NewMessageViewController? {
        self.navigationController?.popViewControllerAnimated(false)
        previousViewController.selectedMessage = message
        previousViewController.licenseTextField.text = licenseTextField.text
        previousViewController.sendMessageToLicensePlate(self.licenseTextField.text)
      }
    }
  }
}