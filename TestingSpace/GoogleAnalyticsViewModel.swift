//
//  GoogleAnalyticsViewModel.swift
//  TestingSpace
//
//  Created by Manuel Aurora on 18.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Foundation
import RxSwift

struct GoogleAnalyticsViewModel
{
    private let gaDataSource: IntegratedServicesDataManager
    
    init(datasource: IntegratedServicesDataManager) {
        gaDataSource = datasource
    }
    
    func getViewId(token: String) -> Observable<[(viewID: String, webSiteUri: String)]> {
        let request = GAnalytics(oauthToken: token, oauthRefreshToken: "", oauthTokenExpiresAt: Date())        
        return request.getViewID()
    }
    
    func getReport(viewID: String, kpiName: String, token: String) -> Observable<resultArray> {
        gaDataSource.kpiName    = kpiName
        gaDataSource.oauthToken = token
        gaDataSource.viewId     = viewID
        
        return gaDataSource.createDataFromRequest()
    }
}
