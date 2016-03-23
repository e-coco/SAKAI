//
//
//  Modified by YAMANE on 2015/08/20.
//  Created by 伊藤　誠 on 2015/06/08.
//  Copyright (c) 2015年 NPO法人 情熱の赤いバラ協会. All rights reserved.
//
import CoreLocation
import WebKit


/** 情報整理中
 ** 基本（グラウンド、スポット）ビュー
 **/
class FirstViewController: X0402ViewController, CLLocationManagerDelegate, NSXMLParserDelegate{
    typealias OwnClass                                               =  FirstViewController
    private static let groundTopTerms: [String:String]               =  [
        "host":OwnClass.hostAddress,
        "path":"/\(OwnClass.series)/\(OwnClass.pathMain)\(OwnClass.cgiTail)"]
    private let groundView: WKWebView                                =  WKWebView()
    private let spotView: WKWebView                                  =  {
        let spotView: WKWebView  =  WKWebView()
        let layer: CALayer       =  spotView.layer
        OwnClass._setShadow(layer)
        return spotView
    }()
    private let spotWindow: UIWindow                                 =  {
        let window: UIWindow     =  UIWindow()
        window.backgroundColor   =  UIColor.clearColor()
        return window
    }()
    private let locationManager: CLLocationManager                   =  {
        let manager: CLLocationManager   =  CLLocationManager()
        manager.desiredAccuracy          =  kCLLocationAccuracyHundredMeters
        manager.distanceFilter           =  100
        manager.activityType             =  CLActivityType.Other
        return manager
    }()
    private let beaconRegions: [CLBeaconRegion]                      =  OwnClass._getBeaconRegions()
    private let indrawImage: UIImage?                                =  UIImage(named: "ecoco_btn")/* スポットFULL化ボタン */
    private let outdrawImage: UIImage?                               =  UIImage(named: "close_btn")/* スポットMINI化ボタン */
    private let unpinnedImage: UIImage?                              =  UIImage(named: "pin_dis")/* ピン・オフ画像 */
    private let pinnedImage: UIImage?                                =  UIImage(named: "pin_enb")/* ピン・オン画像 */
    private let drawButton: UIButton                                 =  {
        let drawButton: UIButton     =  UIButton()
        drawButton.frame             =  CGRect(x: 5, y: 5, width: 70, height: 70)
        OwnClass._setShadow(drawButton.layer)
        return drawButton
    }()
    private let drawerPin: UIButton                                  =  UIButton()
    private static let application: UIApplication                    =  UIApplication.sharedApplication()
    private static let authorizationStatusNames: [CLAuthorizationStatus:String]  =  [
        CLAuthorizationStatus.NotDetermined:"NotDetermined",
        CLAuthorizationStatus.Restricted:"Restricted",
        CLAuthorizationStatus.Denied:"Denied",
        CLAuthorizationStatus.AuthorizedAlways:"Always",
        CLAuthorizationStatus.AuthorizedWhenInUse:"WhenInUse"]
    private static let regionStateNames: [CLRegionState:String]                  =  [
        CLRegionState.Inside:"Inside",
        CLRegionState.Outside:"Outside",
        CLRegionState.Unknown:"Unknown"]
    private static let proximityNames: [CLProximity:String]                      =  [
        CLProximity.Unknown:"Unknown",
        CLProximity.Far:"Far",
        CLProximity.Near:"Near",
        CLProximity.Immediate:"Immediate"]
    private static let states: [UIApplicationState]                              =  [
        UIApplicationState.Background,
        UIApplicationState.Inactive]
    private var pinStatus: Bool                                                  =  false// TODO: 精査
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        OwnClass._initializeUserDefaults()
        // <スマート化>
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates  =  false/* 2015-12-28, yamane@RRL */
        } else {
            locationManager.startUpdatingLocation()
        }
        // </スマート化>
        //        _initializeNsUrlMain()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private class func _getBeaconRegions() -> [CLBeaconRegion] {
        let uuids: [String:String]               =  [
            "00000000-467B-1001-B000-001C4DC34010":"ECOCO-Beacon",
            "00000000-62F4-1001-B000-001C4D5EC86F":"kanabea"]
        var regions: [CLBeaconRegion]            =  []
        for (uuid, identifier)                  in  uuids {
            let nsUuid: NSUUID                   =  NSUUID(UUIDString: uuid)!
            let region: CLBeaconRegion           =  CLBeaconRegion(proximityUUID: nsUuid, identifier:
                identifier)
            region.notifyEntryStateOnDisplay     =  false// イベント通知
            region.notifyOnEntry                 =  true// 入域通知
            region.notifyOnExit                  =  true// 退域通知
            regions.append(region)
        }
        return regions
    }
    
    //    /** 整理整頓中
    //    **  グラウンド・ビューのトップURL初期化
    //    **/
    //    private func _initializeNsUrlMain() {
    //        let terms: [String:String]   =  [
    //            "host":OwnClass.hostAddress,
    //            "path":"/\(OwnClass.series)/\(OwnClass.pathMain)\(OwnClass.cgiTail)"]
    //        nsUrlMain                    =  _normalizeNsUrl(terms)
    //    }
    
    /** 整理整頓中
    **  ユーザーデフォルト初期化
    **/
    private class func _initializeUserDefaults() {
        let registerings: [String:String]    =  [
            keyLatitude:latitudeInitial,
            keyLongitude:longitudeInitial]
        _prepare(registerings)
    }
    
    /** 拡張中
     ** ビーコンID の取得
     **/
    private func _getBeaconId(beacon: CLBeacon) -> String {
        let uuid: String     =  beacon.proximityUUID.UUIDString
        let major: String    =  beacon.major.stringValue
        let minor: String    =  beacon.minor.stringValue
        let id: String       =  [uuid, major, minor].joinWithSeparator("#")
        return id
    }
    
    /** UUID毎のビーコン記憶 */
    private var sectionedBeacons: [NSUUID:[CLBeacon]]    =  [:]
    
    /** 直近のビーコンID */
    private var previousBeaconId: String?
    
    
    /** 整理整頓中
     **  ビーコン記憶の忘却
     **/
    private func _clearBeacon(spotWindow: UIWindow, spotView: WKWebView) {
        _turnSpotViewOff(spotWindow, spotView: spotView)
        sectionedBeacons.removeAll()
        previousBeaconId   =  nil
    }
    
    /** 整理整頓中
     **  直近記憶の照合
     **/
    private func _isDifferentBeacon(beacon: CLBeacon) -> Bool {
        let beaconId: String     =  _getBeaconId(beacon)
        let answer: Bool         =  (previousBeaconId !=  beaconId)
        previousBeaconId         =  beaconId
        return answer
    }
    
    /** 整理整頓中
     **  viewロード終了時実処理
     **/
    private func _viewDidLoad() {
        let mainBundle: NSBundle         =  NSBundle.mainBundle()
        super.title                      =  mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName") as! String?/* 2015-12-25, yamane@RRL */// NavigationBarタイトル
        let buttonTitle: String          =  NSLocalizedString("navigationBack", comment: "アラートのタイトル")/* 2015-12-25, yamane@RRL */
        let style: UIBarButtonItemStyle  =  UIBarButtonItemStyle.Plain
        let buttonItem: UIBarButtonItem  =  UIBarButtonItem(title: buttonTitle, style: style, target: nil, action: nil)/* 2015-12-25, yamane@RRL */
        navigationItem.backBarButtonItem =  buttonItem
        let center: NSNotificationCenter =  NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "enterForeground:", name: "applicationWillEnterForeground", object: nil)// appDelegateからの連絡
    }
    
    /** 整理整頓中
     **  view出力前実処理
     **/
    private class func _getFreshRequest(nsUrl: NSURL) -> NSMutableURLRequest {
        let policy: NSURLRequestCachePolicy  =  NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        let request: NSMutableURLRequest     =  NSMutableURLRequest(URL: nsUrl, cachePolicy: policy, timeoutInterval: 60)
        return request
    }
    
    /** 整理整頓中
     **  view出力前実処理
     ToDo: ベストと言えない処理が多い為、処理手順の再検討を
     問題1> viewWillAppear は「ビューを出す直前に毎回」繰り返されるので重い（無駄を書くべきでない）
     1-1> groundView.frame を繰り返し設定するのは無駄で、この瞬間でよいはず
     1-2> _view.addSubview は無駄で、この瞬間でよいはず
     1-3> groundView.navigationDelegate の設定は無駄で、この瞬間でよいはず
     1-4> loadRequest より viewDidLoad かも
     問題2> viewDidAppear ですべき処理が定義されていない
     2-1> 座標都合上、スポット・ビュー座標は viewDidAppear で設定するのが穏当、か
     2-2> ただし viewDidAppear は繰り返し実行される点に要注意
     **/
    private func _frameGroundView(groundView: WKWebView) {
        let frame: CGRect                =  _getBaseFrame()
        let width: CGFloat               =  frame.width
        let height: CGFloat              =  frame.height
        groundView.frame                 =  CGRect(x: 0, y: 0, width: width, height: height)
        let _view: UIView                =  super.view
        _view.addSubview(groundView)
        groundView.navigationDelegate    =  self
    }
    
    /** 整理整頓中
     **  ビーコン・データ出力
     **/
    private func _printBeacon(beacon: CLBeacon) {
        let major: NSNumber                  =  beacon.major
        let minor: NSNumber                  =  beacon.minor
        let proximity: CLProximity           =  beacon.proximity
        let proximityName: String            =  OwnClass.proximityNames[ proximity ]!
        let accuracy: CLLocationAccuracy     =  beacon.accuracy
        let rssi: Int                        =  beacon.rssi
        print("(major#minor, proximity#accuracy, RSSI): (\(major)#\(minor), \(proximityName)#\(accuracy), \(rssi))")
    }
    
    /** 整理整頓中
     ** ビーコン関連問合せURLの取得
     **/
    private func _getBeaconUrl(beacon: CLBeacon, cgiBody: String, fragment: String?) -> NSURL {
        let major: NSNumber                  =  beacon.major
        let minor: NSNumber                  =  beacon.minor
        let parts: [String]                  =  ["stampFormat=xml", "major=\(major)", "minor=\(minor)", "MAJOR=\(major)", "MINOR=\(minor)", "cat=\(major)", "id=\(minor)"]
        var terms: [String:String]           =  [
            "host":OwnClass.hostAddress,
            "path":"/\(OwnClass.series)/\(cgiBody)\(OwnClass.cgiTail)",
            "query":parts.joinWithSeparator("&")]
        if nil                              !=  fragment {
            terms["fragment"]                =  fragment!
        }
        let nsUrl: NSURL                     =  _normalizeNsUrl(terms)
        return nsUrl
    }
    
    /** 整理整頓中
     **  センター通知作成
     **/
    private class func _getLocalNotification(message: String) -> UILocalNotification {
        let notification: UILocalNotification    =  UILocalNotification()
        notification.alertAction                 =  NSLocalizedString("notificationButtonLabel", comment: "通知ダイアログ・クローザー")/* 2015-12-25, yamane@RRL */
        notification.alertBody                   =  message
        notification.regionTriggersOnce          =  true
        notification.timeZone                    =  NSTimeZone.defaultTimeZone()
        notification.fireDate                    =  NSDate(timeIntervalSinceNow: 0)
        notification.soundName                   =  UILocalNotificationDefaultSoundName
        return notification
    }
    
    /** 整理整頓中
     **  通知スケジューリング
     **/
    private class func _scheduleNotification(message: String) {
        let application: UIApplication           =  UIApplication.sharedApplication()
        let notification: UILocalNotification    =  _getLocalNotification(message)
        application.scheduleLocalNotification(notification)
    }
    
    /** 整理整頓中
     **  アラート・アクション取得
     **/
    private func _getAlertAction() -> UIAlertAction {
        let title: String                =  "OK"
        let style: UIAlertActionStyle    =  UIAlertActionStyle.Default
        let action: UIAlertAction        =  UIAlertAction(title: title, style: style, handler: nil)
        return action
    }
    
    /** 整理整頓中
     **  アラート・コントローラー取得
     **/
    private func _getAlertController(message: String) -> UIAlertController {
        let style: UIAlertControllerStyle    =  UIAlertControllerStyle.Alert
        let controller: UIAlertController    =  UIAlertController(title: "", message: message, preferredStyle: style)
        let view: UIView                     = controller.view
        let mainScreen: UIScreen             =  UIScreen.mainScreen()
        view.frame                           =  mainScreen.applicationFrame
        let action: UIAlertAction            =  _getAlertAction()
        controller.addAction(action)
        return controller
    }
    
    /** 整理整頓中
     **  アラート・ダイアログの出力
     **/
    private func _popDialog(message: String) {
        let controller: UIAlertController    =  _getAlertController(message)
        presentViewController(controller, animated: true, completion: nil)
    }
    
    private var dialogStack: [String]    =  []
    
    /** 整理整頓中
     **  アラート通知
     **/
    private func _tryPopDialog() {
        if !dialogStack.isEmpty {
            let message: String  =  dialogStack.joinWithSeparator("\n")
            _popDialog(message)
            dialogStack.removeAll()
        }
    }
    
    /**
     **  文字列の有値判定
     **/
    private class func _hasBody(string: String?) -> Bool {
        guard let real: String   =  string else {
            return false
        }
        return !real.isEmpty
    }
    
    /** 整理整頓中
     **  通知
     **/
    private func _tellStamp(dialogMessage: String?, notificationMessage: String?) {
        if _isBackgrounded() {
            if OwnClass._hasBody(notificationMessage) {
                OwnClass._scheduleNotification(notificationMessage!)
            }
            if OwnClass._hasBody(dialogMessage) {
                dialogStack.append(dialogMessage!)
            }
        } else {
            if OwnClass._hasBody(dialogMessage) {
                _popDialog(dialogMessage!)
            }
        }
    }
    
    /** 整理整頓中
     **  ウェブサーバー返答処理
     **/
    private func _listenStamp(data: NSData?, urlResponse: NSURLResponse?, error: NSError?) {
        if nil                          ==  error {
            let result: NSString?        =  NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("_listenStamp/result: \(result)")
            let parser: NSXMLParser?     =  NSXMLParser(data: data!)
            if nil                      ==  parser {// < パース失敗
                print("failed to parse XML")
            } else {
                parser!.delegate         =  self
                parser!.parse()
            }
        } else {
            print("_listenStamp/error: \(error)")
        }
    }
    
    /** 整理整頓中
     **  スタンプラリーの来訪確認タスク作成
     **/
    private func _getStampTask(nsUrl: NSURL, handle: ((NSData?, NSURLResponse?, NSError?) -> Void)) -> NSURLSessionDataTask {
        let configuration: NSURLSessionConfiguration     =  NSURLSessionConfiguration.defaultSessionConfiguration()
        let session: NSURLSession                        =  NSURLSession(configuration: configuration)
        let task: NSURLSessionDataTask                   =  session.dataTaskWithURL(nsUrl, completionHandler: handle)
        return task
    }
    
    /** 整理整頓中
     **  スタンプラリーの来訪確認
     **/
    private func _stampBeacon(beacon: CLBeacon) {
        let nsUrl: NSURL                 =  _getBeaconUrl(beacon, cgiBody: OwnClass.pathStamp, fragment: nil)
        let task: NSURLSessionDataTask   =  _getStampTask(nsUrl, handle: _listenStamp)
        task.resume()
    }
    
    /** 拡張中
     ** ビーコンID配列の取得
     **/
    private func _getBeaconIds(beaconMap: [NSUUID:[CLBeacon]]) -> [String] {
        var ids: [String]    =  []
        func eatBeacon(beacon: CLBeacon) {
            let id: String   =  _getBeaconId(beacon)
            ids.append(id)
        }
        func eatSectioned(uuid: NSUUID, beacons: [CLBeacon]) {
            beacons.forEach(eatBeacon)
        }
        beaconMap.forEach(eatSectioned)
        return ids
    }
    
    /** 拡張中
     ** ビーコン分類連想配列のフラット化
     **/
    private func _getThruBeacons(sectionedBeacons: [NSUUID:[CLBeacon]]) -> [CLBeacon] {
        var thruBeacons: [CLBeacon]  =  []
        func eatBeacon(beacon: CLBeacon) {
            if CLProximity.Unknown  !=  beacon.proximity {
                thruBeacons.append(beacon)
            }
        }
        func eatSectioned(uuid: NSUUID, beacons: [CLBeacon]) {
            beacons.forEach(eatBeacon)
        }
        sectionedBeacons.forEach(eatSectioned)
        return thruBeacons
    }
    
    /** 整理整頓中
     ** スポット・ビュー整理
     **/
    private func _isAuthorizedWhenInUse() -> Bool {
        return CLAuthorizationStatus.AuthorizedWhenInUse    ==  CLLocationManager.authorizationStatus()
    }
    
    /** 整理整頓中
     ** スポット・ビュー出力
     **/
    private func _spotBeacon(spotWindow: UIWindow, spotView: WKWebView, beacon: CLBeacon) {
        _turnSpotViewOff(spotWindow, spotView: spotView)
        let nsUrl: NSURL                     =  _getBeaconUrl(beacon, cgiBody: OwnClass.pathSpot, fragment: OwnClass.fragmentReloadGround)
        let request: NSMutableURLRequest     =  OwnClass._getFreshRequest(nsUrl)
        spotView.loadRequest(request)
    }
    
    /** 整理整頓中
     **  域内ビーコン群実処理
     **/
    private func _didRangeBeacons(spotWindow: UIWindow, spotView: WKWebView, beacons: [CLBeacon], uuid: NSUUID) {
        let knownBeacons: [String]           =  _getBeaconIds(sectionedBeacons)
        sectionedBeacons[uuid]               =  beacons
        let thruBeacons: [CLBeacon]          =  _getThruBeacons(sectionedBeacons)
        if thruBeacons.isEmpty {
            if _isAuthorizedWhenInUse() {
                _clearBeacon(spotWindow, spotView: spotView)
            }
        } else {
            let sortedBeacons: [CLBeacon]    =  thruBeacons.sort(_compareBeacon)
            sortedBeacons.forEach(_printBeacon)
            let nearestBeacon: CLBeacon      =  sortedBeacons[0]
            if !pinStatus                   &&  _isDifferentBeacon(nearestBeacon) {
                // <スマート化>
                func listenLocation(location: CLLocation?) {
                    OwnClass._driveLocationDefault(location)
                    _spotBeacon(spotWindow, spotView: spotView, beacon: nearestBeacon)
                    let nearestId: String    =  _getBeaconId(nearestBeacon)
                    if !knownBeacons.contains(nearestId) {// < 最寄 & 入域初回
                        _stampBeacon(nearestBeacon)
                    }
                }
                
                _tryLocationDrive(listenLocation)
                // </スマート化>
                //                _spotBeacon(spotWindow, spotView: spotView, beacon: nearestBeacon)
                //                let nearestId: String        =  _getBeaconId(nearestBeacon)
                //                if !knownBeacons.contains(nearestId) {// < 最寄で入域中初回
                //                    _stampBeacon(nearestBeacon)
                //                }
            }
        }
    }
    
    /** 整理整頓中
     **  計測距離によるビーコン比較
     **/
    private func _compareBeacon(left: CLBeacon, right: CLBeacon) -> Bool {
        let leftAccuracy: CLLocationAccuracy     =  left.accuracy
        let compared: Bool                       =  (
            leftAccuracy                        >=  0 &&
                right.accuracy                  >=  leftAccuracy)
        return compared
    }
    
    /** 整理整頓中
     ** ビーコンのレンジング開始
     **/
    private func _startBeaconRanging(manager: CLLocationManager, beaconRegion: CLBeaconRegion) {
        manager.startRangingBeaconsInRegion(beaconRegion)
        dismissViewControllerAnimated(true, completion: nil)// < モーダル状態解除
    }
    
    /** 整理整頓中
     **  退域時の実処理
     **/
    private func _didExitRegion(manager: CLLocationManager, beaconRegion: CLBeaconRegion) {
        print("CLLocationManager:stopRangingBeaconsInRegion(\(beaconRegion.identifier))")
        manager.stopRangingBeaconsInRegion(beaconRegion)// <レンジング停止
    }
    
    /** 整理整頓中
     **  モニタリング諸処理の必要性判定
     **/
    private func _isMonitoringOk() -> Bool {
        let answer: Bool     =  CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion) && CLLocationManager.isRangingAvailable()
        return answer
    }
    
    /** 整理整頓中
     **  モニタリング開始
     **/
    private func startMonitoring(manager: CLLocationManager) {
        // <スマート化>
        //        manager.delegate         =  self
        // </スマート化>
        if _isMonitoringOk() {// < 諸処理する場合
            // <スマート化>
            if #available(iOS 9.0, *) {} else {/* 2015-12-25, yamane@RRL */
                if _isBackgrounded() {// < バックグラウンド状態にある場合
                    manager.startUpdatingLocation()// < ビーコン検知に不可欠な、位置情報のバックグラウンド更新
                }
            }/* 2015-12-25, yamane@RRL */
            // </スマート化>
            for beaconRegion    in  beaconRegions {
                print("CLLocationManager:startMonitoringForRegion(\(beaconRegion.identifier))")
                manager.startMonitoringForRegion(beaconRegion)
            }
        }
    }
    
    /** 整理整頓中
     **  バックグラウンド状態判定
     **/
    private func _isBackgrounded() -> Bool {
        let state: UIApplicationState    =  OwnClass.application.applicationState
        let answer: Bool                 =  OwnClass.states.contains(state)
        return answer
    }
    
    //    /** 整理整頓中
    //    **  ロケーション更新正常時実処理
    //    **  経緯度の出力
    //    **/
    //    private func _didUpdateLocations(coordinate: CLLocationCoordinate2D) {
    //        let latitude: String     =  "\(coordinate.latitude)"
    //        let longitude: String    =  "\(coordinate.longitude)"
    //        OwnClass._memorize(OwnClass.keyLatitude, value: latitude)
    //        OwnClass._memorize(OwnClass.keyLongitude, value: longitude)
    //        print("(latitude, longitude): (\(latitude), \(longitude))")
    //    }
    
    /** 整理整頓中
    ** スポット・ビューのミニ表示
    **/
    private func _turnSpotViewMini() {
        drawerPin.hidden     =  true
        UIView.animateWithDuration(0.3, animations: _animateSpotView)
    }
    
    /** 整理整頓中
     ** グラウンド・ビューへのHTML出力
     **/
    private func _loadGround(terms: [String:String]) {
        func listenLocation(location: CLLocation?) {
            OwnClass._driveLocationDefault(location)
            let recomposed: NSURL                =  _normalizeNsUrl(terms)
            let request: NSMutableURLRequest     =  OwnClass._getFreshRequest(recomposed)
            groundView.loadRequest(request)
        }
        
        _tryLocationDrive(listenLocation)
    }
    
    /** 整理整頓中
     ** グラウンド・ビューの再描画
     **/
    private func _reloadGround() {
        let _navigationController: UINavigationController    =  super.navigationController!
        let topViewController: UIViewController              =  _navigationController.topViewController!
        if topViewController                                is  NextViewController {
            let casted: NextViewController                   =  topViewController as! NextViewController
            casted.viewDidLoad()
        }
    }
    
    /** 整理整頓中
     ** 画面遷移先の取得
     **/
    private func _getTarget(nsUrl: NSURL) -> String {
        let scheme: String       =  nsUrl.scheme
        var target: String       =  scheme.hasPrefix("http")
            ?   "_blank"
            :   "_self"
        let varieties: [String]  =  [ "_blank", OwnClass.fragmentReloadGround, "ground", "_self" ]
        let fragment: String?    =  nsUrl.fragment
        if nil                  !=  fragment {
            if varieties.contains(fragment!) {
                target           =  fragment!
            }
        }
        return target
    }
    
    /** 整理整頓中
     **  グラウンド・ビュー読込み事前処理
     **/
    private func _decidePolicyGroundView(webView: WKWebView, nsUrl: NSURL, outer: Bool) -> WKNavigationActionPolicy {
        var decision: WKNavigationActionPolicy   =  WKNavigationActionPolicy.Allow
        if outer {
            webView.stopLoading()
            _loadOutside(nsUrl)
            decision                             =  WKNavigationActionPolicy.Cancel
        } else {
            if "nativ"                          ==  nsUrl.scheme {
                webView.stopLoading()
                _viewNext(nsUrl)
            }
        }
        return decision
    }
    
    /** 整理整頓中
     **  スポット・ビュー読込み事前処理
     **/
    private func _decidePolicySpotView(nsUrl: NSURL, userTrigger: Bool) -> WKNavigationActionPolicy {
        var policy: WKNavigationActionPolicy     =  WKNavigationActionPolicy.Allow
        let target: String                       =  _getTarget(nsUrl)
        if userTrigger {// < ユーザー操作である場合
            switch(target) {
            case OwnClass.fragmentReloadGround:// < スポット・ビューの遷移でグラウンド・ビューをリロードする場合
                _reloadGround()
                break
            case "ground":// < グラウンド・ビューで出力する場合
                _turnSpotViewMini()
                groundView.stopLoading()
                var terms: [String:String]       =  _decomposeNsUrl(nsUrl)
                terms["scheme"]                  =  OwnClass.scheme
                _loadGround(terms)
                policy                           =  WKNavigationActionPolicy.Cancel
                break;
            case "_blank":// < 標準ブラウザで出力する場合
                _loadOutside(nsUrl)
                policy                           =  WKNavigationActionPolicy.Cancel
                break;
            default:// < スポット・ビューで画面遷移出力する場合
                break;
            }
        } else {// < リンク押下でない場合
            if( OwnClass.fragmentReloadGround   ==  target ) {
                _reloadGround()
            }
        }
        return policy
    }
    
    /** 整理整頓中
     ** 基礎フレームの取得
     **/
    private func _getBaseFrame() -> CGRect {
        let _view: UIView    =  super.view
        let _frame: CGRect   =  _view.frame
        return _frame
    }
    
    /** 整理整頓中
     **  スポット・ビューのアニメーション
     **/
    private func _animateSpotView() {
        let hidden: Bool             =  drawerPin.hidden
        let image: UIImage?          =  hidden
            ?   indrawImage
            :   outdrawImage
        drawButton.setImage(image, forState: UIControlState.Normal)
        let frame: CGRect            =  _getBaseFrame()
        let width: CGFloat           =  frame.width
        let height: CGFloat          =  frame.height
        let windowHeight: CGFloat    =  hidden
            ?   90
            :   height
        let windowY: CGFloat         =  height
            -   windowHeight
        spotWindow.frame             =  CGRectMake(0, windowY, width, windowHeight)
        let viewY: CGFloat           =  hidden
            ?   10
            :   35
        let viewHeight: CGFloat      =  windowHeight
            -   viewY
        spotView.frame               =  CGRect(x: 10, y: viewY, width: width - 20, height: viewHeight)
    }
    
    /** 整理整頓中
     **  スポット・ビュー開閉
     **/
    func tapSpotHandle(button: UIButton) {
        pinStatus            =  false
        drawerPin.setImage(unpinnedImage, forState: UIControlState.Normal)
        drawerPin.hidden     =  !drawerPin.hidden
        UIView.animateWithDuration(0.3, animations: _animateSpotView)
    }
    
    /** 整理整頓中
     **  スポット・ビューをオフ表示
     **/
    private func _turnSpotViewOff(spotWindow: UIWindow, spotView: WKWebView) {
        func _animateOff() {
            drawButton.setImage(indrawImage, forState: UIControlState.Normal)
            let frame: CGRect        =  _getBaseFrame()
            let width: CGFloat       =  frame.width
            let height: CGFloat      =  frame.height
            spotWindow.frame         =  CGRectMake(0, height, width, 0)
            spotView.frame           =  CGRect(x: 10, y: 10, width: width - 20, height: 80)
        }
        
        UIView.animateWithDuration(0.3, animations: _animateOff)
    }
    
    /** 整理整頓中
     **  ピンのトグル実処理
     **/
    func togglePin(button: UIButton) {
        pinStatus            =  !pinStatus
        let image: UIImage?  =  pinStatus
            ?   pinnedImage
            :   unpinnedImage
        button.setImage(image, forState: UIControlState.Normal)
    }
    
    private func enterForeground(notification: NSNotification) {
        _tryPopDialog()
        if nil  ==  groundView.URL {
            print("enterForeground(\(notification))")
            _loadGround(OwnClass.groundTopTerms)
        }
    }
    
    internal func makeMyWindow(spotWindow: UIWindow, spotView: WKWebView) {
        let frame: CGRect    =  _getBaseFrame()
        _initializeSpotWindow(spotWindow, frame: frame)
        _initializeSpotView(spotView, frame: frame)
        spotWindow.addSubview(spotView)
    }
    
    /** 整理整頓中
     **  spotWindow 初期化
     **/
    private func _initializeSpotWindow(spotWindow: UIWindow, frame: CGRect) {
        spotWindow.frame     =   CGRectMake(0, frame.height, frame.width, 90)
        spotWindow.alpha     =   1.0
        spotWindow.makeKeyAndVisible()// window表示
    }
    
    /** 整理整頓中
     **  SpotView 初期化
     **/
    private func _initializeSpotView(spotView: WKWebView, frame: CGRect) {
        let width: CGFloat           =  frame.width - 20
        spotView.frame               =  CGRect(x: 10, y: 10, width: width, height: 80)
        _configurePin(drawerPin, frame: frame)
        spotView.addSubview(drawerPin)
        _configureDrawButton(drawButton)
        spotView.addSubview(drawButton)
        _configureOpener(spotView, frame: frame)
        spotView.navigationDelegate  =  self
    }
    
    /** 整理整頓中
     **  オープナー初期化
     **/
    private func _configureOpener(spotView: WKWebView, frame: CGRect) {
        let x: CGFloat           =  0
        let y: CGFloat           =  0
        let width: CGFloat       =  frame.width - 20
        let height: CGFloat      =  80
        let opener: UIButton     =  UIButton()
        opener.frame             =  CGRect(x: x, y: y, width: width, height: height)
        opener.addTarget(self, action: "tapSpotHandle:", forControlEvents: UIControlEvents.TouchDown)
        spotView.addSubview(opener)
    }
    
    /** 整理整頓中
     **  基本ボタン初期化
     **/
    private func _configureDrawButton(drawButton: UIButton) {
        drawButton.addTarget(self, action: "tapSpotHandle:", forControlEvents: UIControlEvents.TouchUpInside)
        drawButton.setImage(indrawImage, forState: UIControlState.Normal)
    }
    
    /** 整理整頓中
     **  ピン設置
     **/
    private func _configurePin(drawerPin: UIButton, frame: CGRect) {
        let x: CGFloat       =  frame.width - 70
        let y: CGFloat       =  15
        let width: CGFloat   =  45
        let height: CGFloat  =  45
        drawerPin.frame      =  CGRect(x: x, y: y, width: width, height: height)
        drawerPin.addTarget(self, action: "togglePin:", forControlEvents: UIControlEvents.TouchUpInside)
        drawerPin.setImage(unpinnedImage, forState: UIControlState.Normal)
    }
    
    /** 整理整頓中
     **  陰影効果指定
     **/
    private class func _setShadow(layer: CALayer) {
        let color: UIColor   =  UIColor.blackColor()
        layer.shadowColor    =  color.CGColor// 色
        layer.shadowOffset   =  CGSizeMake(0, 0)// 方向
        layer.shadowOpacity  =  0.3// 透明度
        layer.shadowRadius   =  2.0// ぼかし量
    }
    
    /** 整理整頓中
     ** viewロード終了時イベント
     **/
    override func viewDidLoad() {
        super.viewDidLoad()
        _viewDidLoad()
        // <スマート化>
        //        if #available(iOS 9.0, *) {
        //            locationManager.allowsBackgroundLocationUpdates  =  true
        //        }
        // </スマート化>
        print("CLLocationManager:delegate")
        locationManager.delegate     =  self
        makeMyWindow(spotWindow, spotView: spotView)
    }
    
    /** 整理整頓中
     ** view出力前イベント
     **/
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear(\(animated))")
        _frameGroundView(groundView)
        _loadGround(OwnClass.groundTopTerms)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear(\(animated))")
    }
    
    /* <WKNavigationDelegate> */
    /** 整理整頓中
    ** ウェブ・ビュー読込み事前イベント
    **/
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        let navigationName: String               =  OwnClass.getNavigationName(navigationAction.navigationType)
        print("WKWebView:decidePolicyForNavigationAction: \(navigationName)")
        let request: NSURLRequest                =  navigationAction.request
        let nsUrl: NSURL                         =  request.URL!
        var policy: WKNavigationActionPolicy     =  WKNavigationActionPolicy.Allow
        if webView                              === groundView {
            let outer: Bool                      =  (nil == navigationAction.targetFrame)
            print("WKWebView:decidePolicyForNavigationAction/GroundView: \(outer)")
            // <スマート化>
            //            locationManager.startUpdatingLocation()
            // </スマート化>
            policy                               =  _decidePolicyGroundView(webView, nsUrl: nsUrl, outer: outer)
        } else if webView                       === spotView {
            let userTrigger: Bool                =  (WKNavigationType.LinkActivated == navigationAction.navigationType)
            print("decidePolicyForNavigationAction/SpotView: \(userTrigger)")
            policy                               =  _decidePolicySpotView(nsUrl, userTrigger: userTrigger)
        }
        decisionHandler(policy)
    }
    
    /** 整理整頓中
     ** ウェブ・ビュー読込み終了イベント
     **/
    func webView(view: WKWebView, didFinishNavigation navigation: WKNavigation) {
        print("WKWebView:didFinishNavigation")
        let url: NSURL?  =  view.URL
        if OwnClass._isRightUrl(url) {
            if view     === spotView {
                _turnSpotViewMini()
            }
        } else {
            print("\tview.URL: \(url)")
            _warnCommunication(url!)
        }
    }
    /* </WKNavigationDelegate> */
    
    // <スマート化>
    private func _requestAuthorization(locationManager: CLLocationManager) {
        print("CLLocationManager:requestAlwaysAuthorization()")
        locationManager.requestAlwaysAuthorization()
        //        print("CLLocationManager:requestWhenInUseAuthorization()")
        //        locationManager.requestWhenInUseAuthorization()
    }
    
    private class func _driveLocationDefault(location: CLLocation?) {
        guard let _location: CLLocation      =  location else {
            return
        }
        let point: CLLocationCoordinate2D    =  _location.coordinate
        let latitude: CLLocationDegrees      =  point.latitude
        let longitude: CLLocationDegrees     =  point.longitude
        OwnClass._memorize(OwnClass.keyLatitude, value: latitude.description)
        OwnClass._memorize(OwnClass.keyLongitude, value: longitude.description)
    }
    private var driveLocations: [(CLLocation?) -> Void]  =  []
    
    private func _carryLocationDrive(location: CLLocation?) {
        print("_carryLocationDrive(\(driveLocations.count))")
        guard let driveLocation: (CLLocation?) -> Void   =  driveLocations.popLast() else {
            OwnClass._driveLocationDefault(location)
            return
        }
        driveLocation(location)
    }
    
    private func _tryLocationDrive(_driveLocation: (CLLocation?) -> Void) {
        if #available(iOS 9.0, *) {
            _requestAuthorization(locationManager)
            driveLocations.insert(_driveLocation, atIndex: 0)
            print("CLLocationManager:requestLocation(\(driveLocations.count))")
            locationManager.requestLocation()
        } else {
            _driveLocation(locationManager.location)
        }
    }
    // </スマート化>
    
    /* <CLLocationManagerDelegate> */
    /** 整理整頓中
    ** 認証ステータス変更イベント
    **/
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        let statusName: String   =  OwnClass.authorizationStatusNames[ status ]!
        print("CLLocationManager:didChangeAuthorizationStatus: \(statusName)")// 認証ステータスをログ出力
        switch status {
        case CLAuthorizationStatus.NotDetermined:
            // 認証ダイアログ表示
            _requestAuthorization(locationManager)
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            for beaconRegion    in  beaconRegions {
                _startBeaconRanging(manager, beaconRegion: beaconRegion)
            }
        case CLAuthorizationStatus.AuthorizedAlways:
            startMonitoring(manager)
        default:
            break
        }
    }
    
    /** 整理整頓中
     ** ロケーション更新正常時イベント
     **/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation?    =  locations.last
        print("CLLocationManager:didUpdateLocations: \(locations.count), (\(location?.coordinate.latitude), \(location?.coordinate.longitude))")
        // <スマート化>
        _carryLocationDrive(location)
        // </スマート化>
        //        let location: CLLocation                 =  manager.location!
        //        let coordinate: CLLocationCoordinate2D   =  location.coordinate
        //        _didUpdateLocations(coordinate)
    }
    
    /** 整理整頓中
     **/
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError: \(error)")
        // <スマート化>
        if #available(iOS 9.0, *) {
            _carryLocationDrive(manager.location)
        }
        // </スマート化>
    }
    
    /** 整理整頓中
     ** モニタリング開始イベント
     ** (Delegate didDetermineStateへ STEP4)
     */
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        print("CLLocationManager:didStartMonitoringForRegion(\(region.identifier))")
        manager.requestStateForRegion(region as! CLBeaconRegion)// 域内ビーコンを確認
    }
    
    /** 整理整頓中
     ** リージョン管理エラー・イベント
     **/
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("CLLocationManager:monitoringDidFailForRegion(\(region?.identifier)): \(error)")
    }
    
    /** 整理整頓中
     ** 定期レンジング・イベント
     **/
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        print("CLLocationManager:didRangeBeacons(\(region.identifier)): \(beacons.count)")
        let uuid: NSUUID     =  region.proximityUUID
        _didRangeBeacons(spotWindow, spotView: spotView, beacons: beacons, uuid: uuid)
    }
    
    /** 整理整頓中
     ** 入域イベント
     **/
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("CLLocationManager:didEnterRegion(\(region.identifier))")
        _startBeaconRanging(manager, beaconRegion: region as! CLBeaconRegion)
    }
    
    /** 整理整頓中
     ** リージョン開始イベント
     **/
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion inRegion: CLRegion) {
        let stateName: String    =  OwnClass.regionStateNames[ state ]!
        print("CLLocationManager:didDetermineState(\(inRegion.identifier)): \(stateName)")
        if CLRegionState.Inside ==  state {// 入域している場合
            _startBeaconRanging(manager, beaconRegion: inRegion as! CLBeaconRegion)
        }
    }
    
    /** 整理整頓中
     ** 退域イベント
     **/
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("CLLocationManager:didExitRegion(\(region.identifier))")
        _clearBeacon(spotWindow, spotView: spotView)
        _didExitRegion(manager, beaconRegion: region as! CLBeaconRegion)
    }
    
    //    /** 整理整頓中
    //     **/
    //    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
    //        print("didFinishDeferredUpdatesWithError")
    //    }
    //
    //    /** 整理整頓中
    //     **/
    //    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
    //        print("locationManagerDidPauseLocationUpdates")
    //    }
    //
    //     /** 整理整頓中
    //     **/
    //    func locationManagerDidResumeLocationUpdates(manager: CLLocationManager) {
    //        print("locationManagerDidPauseLocationUpdates")
    //    }
    //
    //     /** 整理整頓中
    //     **/
    //    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    //        print("didUpdateHeading")
    //    }
    //
    //     /** 整理整頓中
    //     **/
    //    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
    //        print("locationManagerShouldDisplayHeadingCalibration")
    //        return true
    //    }
    //
    //     /** 整理整頓中
    //     **/
    //    func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    //        print("rangingBeaconsDidFailForRegion")
    //    }
    //
    //     /** 整理整頓中
    //     **/
    //    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
    //        print("didVisit")
    //    }
    /* </CLLocationManagerDelegate> */
    
    /* <NSXMLParserDelegate> */
    private var xmls: [String:String]    =  [:]
    private var tagStack: [String]       =  []
    
    func parserDidStartDocument(parser: NSXMLParser) {
        xmls.removeAll()
        tagStack.removeAll()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String:String]) {
        tagStack.append(elementName)
        if "response"           ==  elementName {
            for ( key, value )  in  attributes {
                xmls[key]        =  value
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters found: String) {
        if !tagStack.isEmpty {
            let dotted: String   =  tagStack.joinWithSeparator(".")
            xmls[dotted]         =  found
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        tagStack.removeLast()
    }
    
    /** 整理整頓中
     ** stamp 返答のXMLパース・コールバック
     **/
    func parserDidEndDocument(parser: NSXMLParser) {
        if "ok" ==  xmls["answer"] {
            let dialog: String?          =  xmls["response.dialog"]
            let notification: String?    =  xmls["response.notification"]
            _tellStamp(dialog, notificationMessage: notification)
        }
        print("parserDidEndDocument")
    }
    //    parser(_:didStartMappingPrefix:toURI:)
    //    parser(_:didEndMappingPrefix:)
    //    parser(_:resolveExternalEntityName:systemID:)
    //    parser(_:parseErrorOccurred:)
    //    parser(_:validationErrorOccurred:)
    //    parser(_:foundIgnorableWhitespace:)
    //    parser(_:foundProcessingInstructionWithTarget:data:)
    //    parser(_:foundComment:)
    //    parser(_:foundCDATA:)
    /* </NSXMLParserDelegate> */
}