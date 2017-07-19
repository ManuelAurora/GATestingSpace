//
//  GoogleAnalytics.swift
//  CoreKPI
//
//  Created by Семен on 02.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift
import SwiftyJSON

class GAnalytics: ExternalRequest
{
    func getViewID() -> Observable<[(viewID: String, webSiteUri: String)]> {
        let url     = "https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties/~all/profiles"
        let headers = ["Authorization" : "Bearer \(oauthToken)"]
        let requestObservable: Observable<JSON> = getJson(url: url,
                                                          header: headers,
                                                          params: nil,
                                                          method: .get)
        return requestObservable
            .map { json in
                var viewsArray: [(viewID: String, webSiteUri: String)] = []
                
                if let items = json["items"].array
                {
                    items.forEach { json in
                        let viewId = json["id"].stringValue
                        let link = json["websiteUrl"].stringValue
                        viewsArray.append((viewID: viewId, webSiteUri: link))
                    }
                }
                return viewsArray
        }
    }
    
    func getAnalytics(param: ReportRequest) -> Observable<Report?> {
        return analyticsRequest(param: param)
    }
    
    private func analyticsRequest(param: ReportRequest) -> Observable<Report?> {
        
        let url = "https://analyticsreporting.googleapis.com."
        let uri = "/v4/reports:batchGet"
        
        let jsonString = param.toJSON()
        
        let params: [String : Any] = ["reportRequests" : jsonString]
        let headers = ["Authorization" : "Bearer \(oauthToken)"]
        
        let responseObservable = self.getJson(url: url+uri, header: headers, params: params, method: .post)
        
        return responseObservable.map { (json) -> Report? in
            if let reports = json["reports"].array
            {
                let data = reports[0].dictionaryObject!
                let report = Report(JSON: data)
                return report
            }
            else { return nil }
        }
    }
}
