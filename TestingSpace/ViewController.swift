//
//  ViewController.swift
//  TestingSpace
//
//  Created by Manuel Aurora on 18.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Cocoa
import Foundation
import RxSwift
import RxCocoa

enum RequestError: Error
{
    case undableToGetViewID
    case errorGettingData
}

class ViewController: NSViewController, BindableType
{
    var viewModel: GoogleAnalyticsViewModel!
    
    private var viewId: String?
    private let bag = DisposeBag()
    
    @IBOutlet weak var dumpButton: NSButton!
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var selectedKPIName: NSPopUpButton!
    @IBOutlet weak var dumpTextView: NSTextView!
    
    override func viewDidLoad() {
        let dataManager = IntegratedServicesDataManager()
        let viewModel = GoogleAnalyticsViewModel(datasource: dataManager)
        self.viewModel = viewModel
        bindViewModel()
        
        selectedKPIName.removeAllItems()
        selectedKPIName.addItems(withTitles: [
            "Users",
            "Audience Overview",
            "Goal Overview",
            "Top Pages by Pageviews",
            "Top Sources by Sessions",
            "Top Organic keywords by session",
            "Top Channels by sessions",
            "Revenue/ Transactions",
            "Ecommerce Overview",
            "Revenue by landing page",
            "Revenue by Channels",
            "Top Keywords by Revenue",
            "Top Sources by Revenue",
            ])
    }
    
    func bindViewModel() {
        let tapObservable = dumpButton.rx.tap
            .do(onNext: { _ in
                self.dumpTextView.textStorage?.mutableString.setString("")
            })
            .debounce(0.5, scheduler: MainScheduler.instance)
            .flatMap { _ in
                return self.viewModel.getViewId(token: self.tokenTextField.stringValue)
            }
        
        let gaDataObservable = tapObservable
            .filter { $0.count > 0 }
            .flatMap { [unowned self] tupleArray -> Observable<resultArray> in
            let viewID  = tupleArray.first!.viewID
            let token   = self.tokenTextField.stringValue
            let kpiName = self.selectedKPIName.selectedItem!.title
            return self.viewModel.getReport(viewID: viewID, kpiName: kpiName, token: token)
        }
        
        gaDataObservable
            .subscribe(onNext: { (result) in
                var resultString = ""
                result.forEach { element in
                    resultString.append("Key: \(element.leftValue)  Value: \(element.rightValue)\n")
                }
                self.dumpTextView.textStorage?.mutableString.setString(resultString)
            }, onError: { (error) in
                print(error)
            })
            .disposed(by: bag)
    }
    
    func getViewID(token: String) -> Observable<[(viewID: String, webSiteUri: String)]> {
        let request = GAnalytics(oauthToken: token, oauthRefreshToken: "", oauthTokenExpiresAt: Date())
        
        return request.getViewID()
    }
}



