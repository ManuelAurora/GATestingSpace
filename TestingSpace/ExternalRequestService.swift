//
//  ExternalRequestService.swift
//  CoreKPI
//
//  Created by Семен on 07.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import Cocoa
import Alamofire
import OAuthSwift
import SwiftyJSON
import RxSwift

struct GACredentialsInfo
{
    var token: String?
    var refreshToken: String?
    var expiresAt:  Date?
    var viewID: String?
    var siteURL: String?
}

struct PPCredentialsInfo
{
    let profileName: String?
}

class ExternalRequest
{    
    var errorMessage: String?
    var oauthToken: String
    var oauthRefreshToken: String
    var oauthTokenExpiresAt: Date
    
    init(oauthToken: String, oauthRefreshToken: String, oauthTokenExpiresAt: Date) {
        self.oauthToken = oauthToken
        self.oauthRefreshToken = oauthRefreshToken
        self.oauthTokenExpiresAt = oauthTokenExpiresAt
    }
    
    init() {
        self.oauthToken = ""
        self.oauthRefreshToken = ""
        self.oauthTokenExpiresAt = Date()
    }
    
    typealias success = (_ json: NSDictionary) -> ()
    typealias failure = (_ error: String) -> ()
    
    //MARK: - Send request
    func getJson(url: String,
                 header: [String : String]?,
                 params: [String: Any]?,
                 method: HTTPMethod) -> Observable<JSON> {
        
        let mainResponse = PublishSubject<JSON>()
            
        request(url, method: method, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { response in
            guard let data = response.data else { return }
            let json = JSON(data: data)
            
            mainResponse.onNext(json)
        }
        
        return mainResponse
    } 
}
