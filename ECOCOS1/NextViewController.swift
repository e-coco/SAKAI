//
//  RightViewController.swift
//  ECOCOS1
//
//  Created by yamane@akabara.or.jp on 2015/09/08.
//  Copyright (c) 2015年 NPO法人情熱の赤いバラ協会. All rights reserved.
//
import WebKit


/** 情報整理中
 ** 遷移先のビュー
 **/
class NextViewController: X0402ViewController{
    typealias OwnClass               =  NextViewController
    private let webView: WKWebView   =  {
        let webView: WKWebView   =  WKWebView()
        webView.backgroundColor  =  OwnClass.whiteColor
        webView.alpha            =  0.0
        return webView
    }()
    private var request: NSMutableURLRequest?
    
    
    /** 整理整頓中
     ** URL設定
     **/
    internal func _setUrl(nsUrl: NSURL) {
        let policy: NSURLRequestCachePolicy  =  NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        request                              =  NSMutableURLRequest(URL: nsUrl, cachePolicy: policy, timeoutInterval: 60)
    }
    
    /** 整理整頓中
     ** タイトル設定
     **/
    internal func _setTitle(title: String) {
        super.title  =  title
    }
    
    /** 整理整頓中
     ** ビューロード終了時実処理
     **/
    private func _viewDidLoad() {
        webView.navigationDelegate   =  self
        webView.loadRequest(request!)
    }
    
    /** 整理整頓中
     ** ビュー出力前実処理
     **/
    private func _viewWillAppear(animated: Bool) {
        let _view: UIView        =  super.view
        _view.backgroundColor    =  OwnClass.whiteColor
        webView.frame            =  _view.frame
        _view.addSubview(webView)
    }
    
    /** 整理整頓中
     ** ナビ・バーへの[戻る]設定
     **/
    private func setNavigationBack() {
        let buttonTitle: String              =  NSLocalizedString("navigationBack", comment: "戻る")/* 2015-12-25, yamane@RRL */
        //        let buttonTitle: String              =  OwnClass.labelNavigationBackward
        let style: UIBarButtonItemStyle      =  UIBarButtonItemStyle.Plain
        let backItem: UIBarButtonItem        =  UIBarButtonItem(title: buttonTitle, style: style, target: nil, action: nil)
        navigationItem.backBarButtonItem     =  backItem
    }
    
    /** 整理整頓中
     ** HTML読込み事前処理
     **/
    private func _decidePolicyForNavigationAction(webView: WKWebView, navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        var decision: WKNavigationActionPolicy   =  WKNavigationActionPolicy.Allow
        setNavigationBack()
        let request: NSURLRequest                =  navigationAction.request
        let nsUrl: NSURL                         =  request.URL!
        if nil                                  ==  navigationAction.targetFrame {
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
     **  ビューロード終了時実処理
     **/
    private func _didFinishNavigation(view: WKWebView) {
        let nsUrl: NSURL?    =  view.URL
        if OwnClass._isRightUrl(nsUrl) {
            func _handleAnimation() {
                view.alpha   =  1.0
            }
            
            UIView.animateWithDuration(0.2, animations: _handleAnimation)
        } else {
            print("\tview.URL:\(nsUrl)")
            _warnCommunication(nsUrl)
        }
    }
    
    /** 整理整頓中
     **  ビューロード終了イベント
     **/
    override func viewDidLoad() {
        super.viewDidLoad()
        _viewDidLoad()
    }
    
    /** 整理整頓中
     **  ビュー出力前イベント
     **/
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _viewWillAppear(animated)
    }
    
    /* <WKNavigationDelegate> */
    /** 整理整頓中
    ** ページ読込み開始イベント
    **/
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        let navigationName: String               =  OwnClass.getNavigationName(navigationAction.navigationType)
        print("decidePolicyForNavigationAction: \(navigationName)")
        let policy: WKNavigationActionPolicy     =  _decidePolicyForNavigationAction(webView, navigationAction: navigationAction)
        decisionHandler(policy)
        
    }
    
    /** 整理整頓中
     ** ページ読込み終了イベント
     **/
    func webView(view: WKWebView, didFinishNavigation navigation: WKNavigation) {
        _didFinishNavigation(view)
    }
    //    webView(_:didCommitNavigation:)
    //    webView(_:didFailNavigation:withError:)
    //    webView(_:didFailProvisionalNavigation:withError:)
    //    webView(_:didReceiveAuthenticationChallenge:completionHandler:)
    //    webView(_:didReceiveServerRedirectForProvisionalNavigation:)
    //    webView(_:didStartProvisionalNavigation:)
    //    webView(_:decidePolicyForNavigationResponse:decisionHandler:)
    /* </WKNavigationDelegate> */
}