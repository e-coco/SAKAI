//
//  AppDelegate.swift
//  ECOCOS1
//
//  Modified by YAMANE on 2015/07/17.
//  Created by 伊藤　誠 on 2015/06/13.
//  Copyright (c) 2015年 NPO法人情熱の赤いバラ協会. All rights reserved.
//
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{
    typealias OwnClass                                           =  AppDelegate
    /** StoryBoard 使用に UIWindow が必要なため用意 */
    let _window: UIWindow                                        =  {
        let mainScreen: UIScreen         =  UIScreen.mainScreen()
        let frame: CGRect                =  mainScreen.bounds
        let window: UIWindow             =  UIWindow(frame: frame)
        return window
    }()
    private static let notificationCenter: NSNotificationCenter  =  NSNotificationCenter.defaultCenter()
    
    
    
    /** 整理整頓中
     ** Notificationの初期化
     **/
    private class func _initializeNotification(application: UIApplication) {
        let type: UIUserNotificationType             =  [
            UIUserNotificationType.Alert,
            UIUserNotificationType.Badge,
            UIUserNotificationType.Sound]
        let settings: UIUserNotificationSettings     =  UIUserNotificationSettings(forTypes: type, categories: nil)
        application.registerUserNotificationSettings(settings)
        OwnClass.notificationCenter.postNotificationName("applicationWillEnterForeground", object: nil)
    }
    
    /** 整理整頓中
     **  スプラッシュ中の初期化処理
     **/
    private class func _didFinishLaunchingWithOptions(application: UIApplication) -> Bool {
        _initializeNotification(application)
        sleep(3)// スプラッシュ時間
        return true
    }
    
    /** 整理整頓中
     ** フォアグラウンド化直前イベント
     **/
    private func _applicationWillEnterForeground(application: UIApplication) {
        application.cancelAllLocalNotifications()
        guard let window: UIWindow               =  _window else {
            return
        }
        guard let _controller: UIViewController  =  window.rootViewController else {
            return
        }
        _controller.loadView()
        _controller.viewDidLoad()
    }
    
    /* <UIApplicationDelegate> */
    /** 整理整頓中
    **  スプラッシュ画面表示終了イベント
    **/
    func application(target: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let first: FirstViewController   =  FirstViewController()
        _window.rootViewController       =  UINavigationController(rootViewController: first)
        _window.makeKeyAndVisible()
        return OwnClass._didFinishLaunchingWithOptions(target)
    }
    
    /** 整理整頓中
     **
     **/
    func application(didRegisterUserNotificationSettings options: [NSObject: AnyObject]?) -> Bool {
        return true
    }
    
    /** 整理整頓中
     ** フォアグラウンド化直前イベント
     **/
    func applicationWillEnterForeground(application: UIApplication) {
        _applicationWillEnterForeground(application)
    }
    
    //    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool { return true }
    /* </UIApplicationDelegate> */
}