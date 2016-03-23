//
//  X0402ViewController.swift
//  ECOCOS1
//
//  Created by YAMANEToy on 2015/09/23.
//  Copyright © 2015年 NPO法人情熱の赤いバラ協会. All rights reserved.
//
import WebKit


class X0402ViewController: AbstractViewController{
    typealias OwnClass                               =  X0402ViewController
    internal static let x0402: Int                   =  27140// 「いいココ！堺」
    //    internal static let viewTitle: String            =  "いいココ！堺"/* 2015-12-25, yamane@RRL */
    internal static let latitudeInitial: String      =  "34.5732256"// 北緯@堺市役所
    internal static let longitudeInitial: String     =  "135.4829072"// 東経@堺市役所
    
    
    /** 整理整頓中
    ** URLパラメータ生成
    **/
    private func _getRichQuery(terms: String?...) -> String {
        let refresher: CFTimeInterval    =  CACurrentMediaTime()
        let latitude: String             =  OwnClass._remember(OwnClass.keyLatitude)
        let longitude: String            =  OwnClass._remember(OwnClass.keyLongitude)
        var parts: [String]              =  [
            refresher.description,
            "hostAddress=\(OwnClass.hostAddress)",
            "series=\(OwnClass.series)",
            "x0402=\(OwnClass.x0402)",
            "os=\(OwnClass.os)",
            "locale=\(i18n)",
            "LANG=\(i18n)",
            "clientId=\(OwnClass.clientId)",
            "UIID=\(OwnClass.clientId)",
            "uiid=\(OwnClass.clientId)",
            "language=\(OwnClass.language)",/* 2015-12-11, yamane@RRL */
            "country=\(OwnClass.country)",/* 2015-12-11, yamane@RRL */
            "latitude=\(latitude)",
            "longitude=\(longitude)",
            "lat=\(latitude)",
            "lon=\(longitude)"]
        for term                        in  terms {
            if nil                      !=  term {
                parts.append(term!)
            }
        }
        let richQuery: String            =  parts.joinWithSeparator("&")
        return richQuery
    }
    
    /**
     ** URL連想配列からNSURLの取得
     ** "[SCHEME]://[user:password?@][host][:port?][path][?query?][#fragment?]"
     ** -> "[scheme]://[user:password?@][host][:port?][path][?addedQuery?][#fragment?]"
     **/
    internal func _normalizeNsUrl(terms: [String:String]) -> NSURL {
        var composing: [String:String]   =  terms
        composing["scheme"]              =  OwnClass.scheme
        composing["query"]               =  _getRichQuery(terms["query"])
        return _composeNsUrl(composing)
    }
    
    /** 整理整頓中
     ** ナビゲーション次画面URLの取得
     **/
    internal func _getNsUrlNext(nsUrl: NSURL) -> NSURL {
        let terms: [String:String]   =  _decomposeNsUrl(nsUrl)
        let nsUrlNext: NSURL         =  _normalizeNsUrl(terms)
        return nsUrlNext
    }
    
    /** 整理整頓中
     ** URLからの画面タイトル取得
     **/
    private class func _getTitle(nsUrl: NSURL) -> String {
        let mainBundle: NSBundle     =  NSBundle.mainBundle()/* 2015-12-25, yamane@RRL */
        let viewTitle: String        =  mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName") as! String/* 2015-12-25, yamane@RRL */
        guard let query: String      =  nsUrl.query else {
            return viewTitle
        }
        guard let decoded: String    =  query.stringByRemovingPercentEncoding else {
            return viewTitle
        }
        let alphas: [String]         =  decoded.componentsSeparatedByString("_NAME_")
        guard let alpha: String      =  alphas.last else {
            return viewTitle
        }
        let betas: [String]          =  alpha.componentsSeparatedByString("NAME=")
        guard let beta: String       =  betas.last else {
            return viewTitle
        }
        return beta
    }
    
    /** 整理整頓中
     ** ナビゲーション通りの自然画面遷移
     **/
    internal func _viewNext(nsUrl: NSURL) {
        let next: NextViewController             =  NextViewController()
        let nsUrlNext: NSURL                     =  _getNsUrlNext(nsUrl)
        next._setUrl(nsUrlNext)
        let title: String                        =  OwnClass._getTitle(nsUrl)
        next._setTitle(title)
        let _controller: UINavigationController? =  super.navigationController
        _controller?.pushViewController(next, animated: true)
    }
}
