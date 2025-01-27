//
//  NewMessageViewController.swift
//  conduit
//
//  Created by Nisha Masharani on 3/8/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import Foundation
import UIKit

class NewMessageViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
  // Init selected message to "" because  you can't send an empty message
  var selectedMessage = ""

  var presetMessages: [String] = []
  var licensePlate: String!
  var participantIdentifiers : [String] = []
  
  @IBOutlet weak var toFieldBackground: UIView!
  @IBOutlet weak var licensePlateLabel: UILabel!
  @IBOutlet weak var presetTable: UITableView!
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    AnalyticsHelper.trackScreen("NewMessage")
    presetTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
    presetTable.separatorInset = UIEdgeInsetsZero
    presetTable.reloadData()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.presetMessages = DataStore.sharedInstance.readPresetMessages()
    
    toFieldBackground.backgroundColor = StyleColor.getColor(.Grey, brightness: .Light)
    licensePlateLabel.text = licensePlate
    presetTable.reloadData()
    
    StyleHelpers.setBackButton(self.navigationItem, label: "Back")

  }

  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    cell.separatorInset = UIEdgeInsetsZero
    cell.layoutMargins = UIEdgeInsetsZero
    cell.preservesSuperviewLayoutMargins = false
  }
  
  // These functions manage the preset message list.
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return presetMessages.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("PresetListItem", forIndexPath: indexPath) as! NewMessageTableViewCell
    cell.label.text = presetMessages[indexPath.row]
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    AnalyticsHelper.trackTouchEvent("send_preset_message")
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! NewMessageTableViewCell
    self.selectedMessage = cell.label.text!
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    performSegueWithIdentifier("create_conversation", sender: self)
  }
  
  func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    var button = UIButton()
    button.setTitle("Custom", forState: .Normal)
    button.addTarget(self, action: "goToCustomMessage", forControlEvents: UIControlEvents.TouchUpInside)
    StyleHelpers.setButtonFont(button)
    return button
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.Delete) {
      var message = presetMessages[indexPath.row]
      presetMessages.removeAtIndex(indexPath.row)
      DataStore.sharedInstance.removePresetMessage(message)
      tableView.reloadData()
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    var conversationViewController: ConversationViewController = segue.destinationViewController as! ConversationViewController
    
    if segue.identifier == "create_conversation" {
      var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
      conversationViewController.layerClient = appDelegate.layerClient
      conversationViewController.conversation = nil
      conversationViewController.participantIdentifiers = self.participantIdentifiers
      conversationViewController.messageText = self.selectedMessage
      conversationViewController.licensePlate = self.licensePlate
    }
  
  }
  
  func goToCustomMessage() {
    AnalyticsHelper.trackButtonPress("custom_message")
    performSegueWithIdentifier("create_conversation", sender: self)
  }
  
  func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 50.0
  }

}

// We have a custom table cell which contains a label, so that we can customize
// the look and positioning of table cells.
class NewMessageTableViewCell : UITableViewCell {
  @IBOutlet weak var label: UILabel!
  
}
