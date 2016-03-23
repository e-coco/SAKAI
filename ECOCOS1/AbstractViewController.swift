//
//  BaseViewController.swift
//  ECOCOS1
//
//  Created by YAMANE on 2015/09/22.
//  Copyright © 2015年 NPO法人情熱の赤いバラ協会. All rights reserved.
//
import WebKit


class AbstractViewController: UIViewController, WKNavigationDelegate{
    typealias OwnClass                                   =  AbstractViewController
    internal static let hostAddress: String              =  "ecoco.mobi"/* ToDo: ecoco.mobi */
    internal static let series: String                   =  "Alpha"/* ToDo: Alpha */
    internal static let os: String                       =  "ios"
    internal static let clientId: String                 =  {
        let keyClient: String                =  "UIID"
        let userDefaults: NSUserDefaults     =  NSUserDefaults.standardUserDefaults()
        let found: String?                   =  userDefaults.stringForKey(keyClient)
        let clientId: String                 =  nil
            ==  found
            ?  {
                let nsUuid: NSUUID       =  NSUUID()
                let clientId: String     =  nsUuid.UUIDString
                userDefaults.setObject(clientId, forKey: keyClient)
                return clientId
                }()                             :  found!
        print("clientId: \(clientId)")
        return clientId
    }()
    internal static let scheme: String                   =  "http"
    internal static let pathMain: String                 =  "index"
    internal static let pathSpot: String                 =  "spot"
    internal static let pathStamp: String                =  "stamp"/* ToDo: stamp, stampStub */
    internal static let cgiTail: String                  =  ".php"
    internal static let fragmentReloadGround: String     =  "reloadGround"
    internal static let keyClientId: String              =  "UIID"
    internal static let keyLatitude: String              =  "UD_LAT"
    internal static let keyLongitude: String             =  "UD_LNG"
    internal static let whiteColor: UIColor              =  UIColor.whiteColor()
    //    internal static let labelNavigationBackward: String      =  "戻る"/* 2015-12-25, yamane@RRL */
    //    internal static let labelNotificationEnd: String         =  "OK"/* 2015-12-25, yamane@RRL */
    //    internal static let messageCommunicationWarn: String     =  "BAD Wi-Fi?\nNow starting Safari.."/* 2015-12-25, yamane@RRL */
    //    internal static let labelCommunicationWarnEnd: String    =  "OK"/* 2015-12-25, yamane@RRL */
    private static let application: UIApplication            =  UIApplication.sharedApplication()
    private static let userDefaults: NSUserDefaults          =  NSUserDefaults.standardUserDefaults()
    
    /**
     ** 選択言語
     **/
     //<言語取扱い統一>
    internal static var language: String                 =  ""
    internal static var country: String                  =  ""
    internal lazy final var i18n: String                 =  {
        let current: NSLocale    =  NSLocale.currentLocale()
        let i18n: String         =  current.localeIdentifier
        let parts: [String]      =  i18n.componentsSeparatedByString("_")
        OwnClass.language        =  parts.first!
        OwnClass.country         =  parts.last!
        print("locale:\(i18n), language:\(OwnClass.language), country:\(OwnClass.country)")
        return i18n
    }()
    //</言語取扱い統一>
    //    internal static let language: String                 =  "ja"
    //    internal static let country: String                  =  "JP"
    //    internal lazy final var i18n: String                 =  {
    //        let i18ns: [String]  =  NSLocale.preferredLanguages()
    //        let i18n: String     =  i18ns[0]
    //        return i18n
    //    }()
    
    internal class func _prepare(registrationDictionary: [String:AnyObject]) {
        userDefaults.registerDefaults(registrationDictionary)
    }
    
    internal class func _memorize(key: String, value: AnyObject) {
        userDefaults.setObject(value, forKey: key)
    }
    
    internal class func _remember(key: String) -> String {
        let answer: String   =  userDefaults.stringForKey(key)!
        return answer
    }
    
    internal static let navigationNames: [WKNavigationType:String]   =  [
        WKNavigationType.BackForward:"BackForward",
        WKNavigationType.FormSubmitted:"FormSubmitted",
        WKNavigationType.FormResubmitted:"FormResubmitted",
        WKNavigationType.LinkActivated:"LinkActivated",
        WKNavigationType.Other:"Other"]
    
    internal class func getNavigationName(type: WKNavigationType) -> String {
        let name: String     =  navigationNames[type]!
        return name
    }
    
    /**
     ** URL連想配列からNSURLの取得
     ** standard: (host, path)
     ** optional: (query, fragment)
     ** possibile: (user, password, port)
     **/
    internal func _composeNsUrl(terms: [String:String]) -> NSURL {
        var parts: [String]  =  ["\(terms["scheme"]!)://"]
        if nil              !=  terms["user"] {
            parts.append(terms["user"]!)
            if nil          !=  terms["password"] {
                parts.append(":\(terms["password"]!)")
            }
            parts.append("@")
        }
        if nil              !=  terms["host"] {
            parts.append(terms["host"]!)
        }
        if nil              !=  terms["port"] {
            parts.append(":\(terms["port"]!)")
        }
        if nil              !=  terms["path"] {
            parts.append(terms["path"]!)
        }
        if nil              !=  terms["query"] {
            parts.append("?\(terms["query"]!)")
        }
        if nil              !=  terms["fragment"] {
            parts.append("#\(terms["fragment"]!)")
        }
        let url: String      =  parts.joinWithSeparator("")
        let nsUrl: NSURL     =  NSURL(string: url)!
        return nsUrl
    }
    
    /**
     ** NSURLからURL連想配列の取得
     ** (scheme, user, password, host, port, path, query, fragment)
     **/
    internal func _decomposeNsUrl(nsUrl: NSURL) -> [String:String] {
        var decomposed: [String:String]  =  [:]
        decomposed["scheme"]             =  nsUrl.scheme
        if nil                          !=  nsUrl.user {
            decomposed["user"]           =  nsUrl.user!
        }
        if nil                          !=  nsUrl.password {
            decomposed["password"]       =  nsUrl.password!
        }
        if nil                          !=  nsUrl.host {
            decomposed["host"]           =  nsUrl.host!
        }
        if nil                          !=  nsUrl.port {
            decomposed["port"]           =  nsUrl.port!.description
        }
        
        if nil                          !=  nsUrl.path {
            decomposed["path"]           =  nsUrl.path!
        }
        if nil                          !=  nsUrl.query {
            decomposed["query"]          =  nsUrl.query!
        }
        if nil                          !=  nsUrl.fragment {
            decomposed["fragment"]       =  nsUrl.fragment!
        }
        return decomposed
    }
    
    /**
     **  URL妥当性判定
     **/
    internal class func _isRightUrl(url: NSURL?) -> Bool {
        let answer: Bool     =  (url?.host == hostAddress)
        return answer
    }
    
    private func _popDialog(title: String, message: String, actionTitle: String, handler: ((UIAlertAction!) -> Void)) {
        let style: UIAlertControllerStyle    =  UIAlertControllerStyle.Alert
        let alerter: UIAlertController       =  UIAlertController(title: title, message: message, preferredStyle: style)
        let actionStyle: UIAlertActionStyle  =  UIAlertActionStyle.Default
        let action: UIAlertAction            =  UIAlertAction(title: actionTitle, style: actionStyle, handler: handler)
        alerter.addAction(action)
        presentViewController(alerter, animated: true, completion: nil)
    }
    
    /**
     **  接続異常の警告とブラウザ起動
     **/
    internal func _warnCommunication(url: NSURL?) {
        func handleAlert(action: UIAlertAction!) {
            guard let _url: NSURL            =  url else {
                return
            }
            let application: UIApplication   =  UIApplication.sharedApplication()
            if application.canOpenURL(_url) {
                application.openURL(_url)
            }
        }
        
        let title: String        =  (nil == url?.host) ? "?" : "\(url!.host!)?"
        let message: String      =  NSLocalizedString("communicationWarnMessage", comment: "接続問題指摘")/* 2015-12-25, yamane@RRL */
        let actionTitle: String  =  NSLocalizedString("communicationWarnButtonLabel", comment: "接続問題指摘ダイアログ・クローザー")/* 2015-12-25, yamane@RRL */
        _popDialog(title, message: message, actionTitle: actionTitle, handler: handleAlert)/* 2015-12-25, yamane@RRL */
    }
    
    /**
     ** 外部ブラウジング
     **/
    internal func _loadOutside(nsUrl: NSURL) {
        OwnClass.application.openURL(nsUrl)
    }
    
    
    /* <WKNavigationDelegate> */
    /** 整理整頓中
    ** リダイレクト検出
    **/
    func webView(view: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        let url: NSURL?          =  view.URL
        if OwnClass.hostAddress !=  url?.host {
            print("didReceiveServerRedirectForProvisionalNavigation:\(url?.absoluteString)")
            _warnCommunication(url)
        }
    }
    
    /** 整理整頓中
     ** 読み込み失敗
     **/
    func webView(view: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let url: NSURL?  =  view.URL
        print("didFailProvisionalNavigation:\(url?.absoluteString)")
        //        _warnCommunication(url)
    }
    //    func webView(view: WKWebView, didCommitNavigation navigation: WKNavigation!)
    //    func webView(view: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError)
    //    func webView(view: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
    //    func webView(view: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
    //    func webView(view: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void)
    /* </WKNavigationDelegate> */
}