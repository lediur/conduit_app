//
//  AppDelegate.swift
//  conduit
//
//  Created by Nathan Eidelson on 3/3/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import UIKit
import GoogleAnalytics_iOS_SDK
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LYRClientDelegate {
  
  // Prod
  let LQSLayerAppIDString = "7b2af17c-db1b-11e4-b5b6-52bb02000413"
  
  // Dev
//  let LQSLayerAppIDString = "7b2aed30-db1b-11e4-a21a-52bb02000413"
  
  var window: UIWindow?
  var layerClient: LYRClient!
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    self.initAppearance()
    
    var appID =  NSUUID(UUIDString: LQSLayerAppIDString)
    layerClient = LYRClient(appID: appID)
    layerClient.delegate = self
    
    self.registerApplicationForPushNotifications(application)
    
    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    
    AnalyticsHelper.initAnalytics()
    // Fabric.with([Crashlytics()])
    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
    self.goToLogin()

    return true
  }
  
  func goToLogin() {
    
    // Go to login if not logged in
    var sessionKey = NSUserDefaults.standardUserDefaults().stringForKey("session")
    let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    
    if (sessionKey == nil) {
      let loginVC : LoginViewController = mainStoryboard.instantiateViewControllerWithIdentifier("loginView") as! LoginViewController
      let rootVC : UINavigationController = UINavigationController(rootViewController: loginVC)
      self.window!.rootViewController = rootVC
      
    } else {
      
      self.authenticateWithLayer({(success, error) in
        if !success {
          
          self.logout()
          
          let loginVC : LoginViewController = mainStoryboard.instantiateViewControllerWithIdentifier("loginView") as! LoginViewController
          let rootVC : UINavigationController = UINavigationController(rootViewController: loginVC)
          self.window!.rootViewController = rootVC
          
        } else {
          let rootVC : SWRevealViewController = mainStoryboard.instantiateViewControllerWithIdentifier("revealView") as! SWRevealViewController
          self.window!.rootViewController = rootVC
        }
      })
    }
  }
  
  func logout() {
    var defaults = NSUserDefaults.standardUserDefaults()
    defaults.removeObjectForKey("session")
    defaults.removeObjectForKey("user")
    defaults.removeObjectForKey("participantIdentifier")
  }
  
  func proceedFromLogin() {
    DataStore.sharedInstance.seed()
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    let rootVC : SWRevealViewController = mainStoryboard.instantiateViewControllerWithIdentifier("revealView") as! SWRevealViewController
    self.window!.rootViewController = rootVC
    
    if NSUserDefaults.standardUserDefaults().boolForKey("isNewAccount") {
      // Go to welcome view
      let destViewController : WelcomeViewController = mainStoryboard.instantiateViewControllerWithIdentifier("welcomeView") as! WelcomeViewController
      
      // This is eventually what we want to do. Right now it gives a blank screen.
      var destNavController = UINavigationController(rootViewController: destViewController)
      
      var navController : UINavigationController = rootVC.frontViewController as! UINavigationController
      
      navController.presentViewController(destNavController, animated: true, completion: nil)
      
    } else {
      var navController : UINavigationController = rootVC.frontViewController as! UINavigationController
      
      var licenseInputViewController = navController.topViewController as! LicenseInputController?
      licenseInputViewController?.licenseField?.becomeFirstResponder()
    }
  }
  
  
  func authenticateWithLayer(completion :(success:Bool,error:NSError?) -> Void) {
    
    self.layerClient.connectWithCompletion({ (success:Bool, error:NSError!) -> Void in
      if (!success) {
        NSLog("Failed to connect to Layer: \(error)");
        completion(success:false, error:error)
      } else {
        
        var currentUser: User = User.getUserFromDefaults()!
        self.authenticateLayerWithUserID(currentUser.emailAddress, completion: { (success, error) -> Void in
          if (!success) {
            NSLog("Failed Authenticating Layer Client with error:\(error)");
            self.layerClient.disconnect()
            completion(success:false, error:error)
          } else {
            completion(success:true, error:nil)
          }
        })
      }
    })
  }
  
  func initAppearance () {
    UINavigationBar.appearance().backgroundColor = StyleColor.getColor(.Primary, brightness: .Medium)
    UINavigationBar.appearance().barTintColor = StyleColor.getColor(.Primary, brightness: .Medium)
    UINavigationBar.appearance().translucent = false
    
    UINavigationBar.appearance().tintColor = TextColor.getTextColor(.Light)
    
    UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: StyleHelpers.FONT_NAME, size: 18.0)!, NSForegroundColorAttributeName : TextColor.getTextColor(.Light)]
      
    UIButton.appearance().backgroundColor = StyleColor.getColor(.Primary, brightness: .Medium)
    UIButton.appearance().tintColor = TextColor.getTextColor(.Light)
    
    UITableView.appearance().backgroundColor = StyleColor.getColor(.Grey, brightness: .Light)
    UITableView.appearance().separatorStyle = .None
    
    UITableViewCell.appearance().layer.borderWidth = 2
    UITableViewCell.appearance().layer.borderColor = StyleColor.getColor(.Grey, brightness: .Light).CGColor
    
    UILabel.appearance().font = UIFont(name: StyleHelpers.FONT_NAME, size: StyleHelpers.FONT_SIZE)
    
    UITextField.appearance().font = UIFont(name: StyleHelpers.FONT_NAME, size: StyleHelpers.FONT_SIZE)
      
  }

  func registerApplicationForPushNotifications(application: UIApplication) {
    if (application.respondsToSelector(Selector("registerForRemoteNotifications"))) {
      //ios 8
      var type = UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound;
      var setting = UIUserNotificationSettings(forTypes: type, categories: nil);
      UIApplication.sharedApplication().registerUserNotificationSettings(setting);
      UIApplication.sharedApplication().registerForRemoteNotifications();
    } else {
      application.registerForRemoteNotificationTypes(UIRemoteNotificationType.Badge | UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound)
    }
  }
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    
    var error: NSError?
    var success = self.layerClient?.updateRemoteNotificationDeviceToken(deviceToken, error: &error)
    if (success != nil) {
      NSLog("Application did register for remote notifications: \(deviceToken)");
      NSUserDefaults.standardUserDefaults().setValue(deviceToken, forKey: "deviceToken");
    } else {
      NSLog("Failed updating device token with error: \(error)");
    }
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
    fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
      
    var error: NSError?      
    var success:Bool =  self.layerClient.synchronizeWithRemoteNotification(userInfo, completion: {(changes,error) in
      if changes != nil {
        if changes.count > 0 {
          var message:LYRMessage = self.messageFromRemoteNotification(userInfo)!
          completionHandler(UIBackgroundFetchResult.NewData)
        } else {
          completionHandler(UIBackgroundFetchResult.NoData)
        }
      } else {
        completionHandler(UIBackgroundFetchResult.Failed)
      }
    })
    
    if success {
      println("Application did complete remote notification sync");
    } else {
      println("Failed processing push notification with error: \(error)");
      completionHandler(UIBackgroundFetchResult.NoData);
    }
    
  }
  
  func setBadgeCountFromRemoteNotification(remoteNotification:NSDictionary) {
    var notification:NSDictionary = remoteNotification.objectForKey("aps") as! NSDictionary
    var currentBadgeCount = notification.objectForKey("badge") as! Int
    UIApplication.sharedApplication().applicationIconBadgeNumber = currentBadgeCount
  }
  
  func messageFromRemoteNotification(remoteNotification:NSDictionary) -> LYRMessage? {
    
    var notification:NSDictionary = remoteNotification.objectForKey("layer") as! NSDictionary
    var message:LYRMessage?
    
    if let messageIdentifier:String = notification.objectForKey("message_identifier") as? String {
      var query:LYRQuery = LYRQuery(`withClass`: LYRMessage.self)
      query.predicate = LYRPredicate(property: "identifier", `operator`: LYRPredicateOperator.IsEqualTo, value: NSURL(string: messageIdentifier))
      
      var error: NSError?
      var conversation:LYRConversation?
      if let messages:NSOrderedSet = self.layerClient?.executeQuery(query, error:&error) {
        if (error != nil) {
          println("Query failed with error \(error)");
        }
        
        // Retrieve the last conversation
        if (messages.count > 0) {
          message = messages.firstObject as? LYRMessage;
        }
      }
    }
    
    if message != nil {
      var messagePart:LYRMessagePart = message!.parts[0] as! LYRMessagePart
      let messageText = NSString(data:messagePart.data!, encoding: NSUTF8StringEncoding)
      println ("Pushed Message Contents: \(messageText!)")
    } else {
      println ("Message couldn't be found")
    }
    
    return message
  }
  
  // MARK: - Layer Authentication Methods
  func authenticateLayerWithUserID(userID:String, completion :(success:Bool,error:NSError?) -> Void)
  {
    if let authenticatedUserID = layerClient.authenticatedUserID {
      println("Layer already authenticated as User \(authenticatedUserID)");
      completion(success:true, error:nil);
    } else {
      /*
      * 1. Request an authentication Nonce from Layer
      */
      layerClient.requestAuthenticationNonceWithCompletion({(nonce, error) in
        if let nonce = nonce {
          /*
          * 2. Acquire identity Token from Layer Identity Service
          */
          self.requestIdentityTokenForUserID(userID, appID: self.layerClient.appID.UUIDString,
            nonce: nonce, completion: { (identityToken, error) in
              
            if let identityToken = identityToken {
              /*
              * 3. Submit identity token to Layer for validation
              */
              self.layerClient.authenticateWithIdentityToken(identityToken, completion: {(authenticatedUserID, error) in
                if let authenticatedUserID = authenticatedUserID {
                  println("Layer authenticated as User: \(authenticatedUserID)");
                  completion(success:true, error:nil);
                } else {
                  NSLog("authenticateWithIdentityToken failed")
                  completion(success:false, error:error);
                }
              })
            } else {
              NSLog("requestIdentityTokenForUserID failed")
              completion(success:false, error:error);
            }
          })
        } else {
          NSLog("requestAuthenticationNonceWithCompletion failed")
          completion(success:false, error:error);
        }
      })
    }
    
    return;
  }
  
  func requestIdentityTokenForUserID(userID:String, appID:String, nonce:String,
    completion :(identityToken:String?,error:NSError?) -> Void) {
    
    let params = ["email_address":userID, "nonce":nonce]
    NSLog("\(params)")
    APIModel.post("users/identity", parameters: params) { (result, error) -> () in
      if error != nil {
        NSLog("Conduit identity token generation error")
        completion(identityToken: nil, error: error)
      } else {
        completion(identityToken: result!["identity"].stringValue, error: nil)
      }
    }
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  // MARK -- LYRClientDelegate Delegate Methods

  func layerClient(client: LYRClient!, didAuthenticateAsUserID userID: String!) {
    NSLog("Layer Client did recieve authentication nonce");
  }
  
  func layerClient(client: LYRClient!, didFailOperationWithError error: NSError!) {
    NSLog("Layer Client did fail operation with error: \(error)");
  }
  
  func layerClient(client: LYRClient!, didFailSynchronizationWithError error: NSError!) {
    NSLog("Layer Client did fail synchronization with error: \(error)");
  }

  
  func layerClient(client: LYRClient!, didFinishSynchronizationWithChanges changes: [AnyObject]!) {
    NSLog("Layer Client did finish sychronization");
  }
  
  func layerClient(client: LYRClient!, didLoseConnectionWithError error: NSError!) {
    NSLog("Layer Client did lose connection with error: \(error)");
  }
  
  func layerClient(client: LYRClient!, didReceiveAuthenticationChallengeWithNonce nonce: String!) {
    NSLog("Layer Client did recieve authentication challenge with nonce: \(nonce)");
  }
  
  func layerClient(client: LYRClient!, willAttemptToConnect attemptNumber: UInt, afterDelay delayInterval: NSTimeInterval, maximumNumberOfAttempts attemptLimit: UInt) {
    NSLog("Layer Client will attempt to connect");
  }
  
  func layerClient(client: LYRClient!, willBeginContentTransfer contentTransferType: LYRContentTransferType, ofObject object: AnyObject!, withProgress progress: LYRProgress!) {
  }
  
  func layerClientDidConnect(client: LYRClient!) {
    NSLog("Layer Client did connect");
  }
  
  func layerClientDidDeauthenticate(client: LYRClient!) {
    NSLog("Layer Client did deauthenticate");
  }
  
  func layerClientDidDisconnect(client: LYRClient!) {
    NSLog("Layer Client did disconnect");
  }

}

