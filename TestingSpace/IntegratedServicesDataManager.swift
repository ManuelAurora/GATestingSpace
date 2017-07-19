//
//  PayPalDataManager.swift
//  CoreKPI
//
//  Created by Manuel Aurora on 24.03.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift

typealias resultArray = [(leftValue: String, centralValue: String, rightValue: String)]


enum GoogleAnalyticsKPIs: String {
    case UsersSessions = "Users"
    case AudienceOverview = "Audience Overview"
    case GoalOverview = "Goal Overview"
    case TopPagesByPageviews = "Top Pages by Pageviews"
    case TopSourcesBySessions = "Top Sources by Sessions"
    case TopOrganicKeywordsBySession = "Top Organic keywords by session"
    case TopChannelsBySessions = "Top Channels by sessions"
    case RevenueTransactions = "Revenue/ Transactions"
    case EcommerceOverview = "Ecommerce Overview"
    case RevenueByLandingPage = "Revenue by landing page"
    case RevenueByChannels = "Revenue by Channels"
    case TopKeywordsByRevenue = "Top Keywords by Revenue"
    case TopSourcesByRevenue = "Top Sources by Revenue"
}

class IntegratedServicesDataManager
{
    var kpiName: String = ""
    var oauthToken: String = ""
    var viewId: String = ""
    
    private var dataForPresent = resultArray()
    private var dataForPresentObservable = PublishSubject<resultArray>()
    
    private var bag = DisposeBag()
    
    func createDataFromRequest() -> Observable<resultArray> {
        
        let dataObservable = getGoogleAnalyticsData()
        
        dataObservable
            .subscribe(onNext: { report in
                if let report = report
                {
                    self.dataFor(report: report)
                }
            })
            .disposed(by: bag)
        
        return dataForPresentObservable.take(1)
    }
    
    private func dataFor(report: Report) {
        dataForPresent.removeAll()
        
        guard report.data?.rowCount != nil else { return }
        
        switch GoogleAnalyticsKPIs(rawValue: self.kpiName)!
        {
        case .UsersSessions:
            for i in 0..<(report.data?.rowCount)! {
                let data = report.data?.rows[i]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/"
                
                dataForPresent.append(("\(dateFormatter.string(from: Date()))\((data?.dimensions[0])!)", "", "\((data?.metrics[0].values[0])!)"))
            }
            
        case .AudienceOverview:
            let metricsInOrder = [
                "Users", "Sessions", "New Sessions %", "Pages / Sessions",
                "Avg. Session dur. sec.", "Bounce rate %", "Pageviews"
            ]
            let numberFormatter = NumberFormatter()
            
            numberFormatter.maximumFractionDigits = 1
            
            if let data = report.data, data.rows.count > 0, data.rows[0].metrics.count > 0
            {
                let dataRows = data.rows[0]
                for (value, metric) in zip(dataRows.metrics[0].values, metricsInOrder)
                {
                    let value = Float(value)!
                    let stringValue = numberFormatter.string(from: NSNumber(value: value))!
                    
                    if metric == metricsInOrder[2]
                    {
                        let stringValue = numberFormatter.string(from: NSNumber(value: (Float(value) * 100)))!
                        dataForPresent.append((leftValue: metric, centralValue: "", rightValue: "\(stringValue)%"))
                    }
                    else if metric == metricsInOrder[5]
                    {
                        dataForPresent.append((leftValue: metric, centralValue: "", rightValue: stringValue + "%"))
                    }
                    else
                    {
                        dataForPresent.append((leftValue: metric, centralValue: "", rightValue: "\(stringValue)"))
                    }
                }
            }
            
        case .GoalOverview:
            for _ in 0..<(report.data?.rowCount)! {
                for data in (report.data?.totals)! {
                    dataForPresent.append(("Goal", "", "\(data.values[0])"))
                }
            }
            
        case .TopPagesByPageviews:
            for i in 0..<(report.data?.rowCount)! {
                let data = report.data?.rows[i]
                dataForPresent.append(("\((data?.dimensions[0])!)", "", "\((data?.metrics[0].values[0])!)"))
            }
            
        case .TopSourcesBySessions:
            for i in 0..<(report.data?.rowCount)! {
                let data = report.data?.rows[i]
                dataForPresent.append(("\((data?.dimensions[0])!)", "", "\((data?.metrics[0].values[0])!)"))
            }
            
        case .TopOrganicKeywordsBySession:
            for i in 0..<(report.data?.rowCount)! {
                let data = report.data?.rows[i]
                dataForPresent.append(("\((data?.dimensions[0])!)", "", "\((data?.metrics[0].values[0])!)"))
            }
            
        case .TopChannelsBySessions:
            for i in 0..<(report.data?.rowCount)! {
                let data = report.data?.rows[i]
                dataForPresent.append(("\((data?.dimensions[0])!)", "", "\((data?.metrics[0].values[0])!)"))
            }
            
        case .RevenueTransactions:
            dataForPresent.append(("Revenue", "", "\((report.data?.totals[0].values[0])!)"))
            
        case .EcommerceOverview:
            for values in (report.data?.totals)! {
                for number in values.values {
                    dataForPresent.append(("OverView", "", "\(number)"))
                }
            }
            
        case .RevenueByLandingPage:
            dataForPresent.append(("Revenue", "", "\((report.data?.totals[0].values[0])!)"))
            
        case .RevenueByChannels:
            dataForPresent.append(("Revenue", "", "\((report.data?.totals[0].values[0])!)"))
            
        case .TopKeywordsByRevenue:
            dataForPresent.append(("Revenue", "", "\((report.data?.totals[0].values[0])!)"))
            
        case .TopSourcesByRevenue:
            dataForPresent.append(("Revenue", "", "\((report.data?.totals[0].values[0])!)"))
        }
        
        dataForPresentObservable.onNext(dataForPresent)
    }
    //MARK: - get analytics data
    func getGoogleAnalyticsData() -> Observable<Report?> {
        let param = ReportRequest()
        
        param.viewId = viewId
        
        var ranges:[ReportRequest.DateRange] = []
        var metrics: [ReportRequest.Metric] = []
        var dimentions: [ReportRequest.Dimension] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let curentDate = dateFormatter.string(from: Date())
        let sevenDaysAgo = dateFormatter.string(from: Date(timeIntervalSinceNow: -(7*24*3600)))
        let mounthAgo = dateFormatter.string(from: Date(timeIntervalSinceNow: -(30*24*3600)))
        
        switch GoogleAnalyticsKPIs(rawValue: kpiName)!
        {
        case .UsersSessions:
            ranges.append(ReportRequest.DateRange(startDate: mounthAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:sessions", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:day"))
        case .AudienceOverview:
            metrics.append(ReportRequest.Metric(expression: "ga:users", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:sessions", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:newUsers/ga:sessions", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:hits/ga:sessions", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:avgSessionDuration", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:bounceRate", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:hits", formattingType: .FLOAT))
            ranges.append(ReportRequest.DateRange(startDate: mounthAgo, endDate: curentDate))
            
        case .GoalOverview:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:goalCompletionsAll", formattingType: .INTEGER))
        case .TopPagesByPageviews:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:pageviews", formattingType: .INTEGER))
            dimentions.append(ReportRequest.Dimension(name: "ga:pagePath"))
        case .TopSourcesBySessions:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:sessions", formattingType: .INTEGER))
            dimentions.append(ReportRequest.Dimension(name: "ga:source"))
        case .TopOrganicKeywordsBySession:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:sessions", formattingType: .INTEGER))
            dimentions.append(ReportRequest.Dimension(name: "ga:keyword"))
        case .TopChannelsBySessions:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:sessions", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:channelGrouping"))
        case .RevenueTransactions:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:totalValue/ga:transactions", formattingType: .FLOAT))
        case .EcommerceOverview:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:itemQuantity", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:uniquePurchases", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:localTransactionShipping", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:localRefundAmount", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:productListViews", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:productListClicks", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:productAddsToCart", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:revenuePerUser", formattingType: .FLOAT))
            metrics.append(ReportRequest.Metric(expression: "ga:transactionsPerUser", formattingType: .FLOAT))
        case .RevenueByLandingPage:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:totalValue", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:landingPagePath"))
        case .RevenueByChannels:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:totalValue", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:channelGrouping"))
        case .TopKeywordsByRevenue:
            ranges.append(ReportRequest.DateRange(startDate: sevenDaysAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:totalValue", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:keyword"))
        case .TopSourcesByRevenue:
            ranges.append(ReportRequest.DateRange(startDate: mounthAgo, endDate: curentDate))
            metrics.append(ReportRequest.Metric(expression: "ga:totalValue", formattingType: .FLOAT))
            dimentions.append(ReportRequest.Dimension(name: "ga:source"))
        }
        
        param.dateRanges = ranges
        param.metrics = metrics
        param.dimensions = dimentions
        let request = GAnalytics(oauthToken: oauthToken, oauthRefreshToken: "", oauthTokenExpiresAt: Date())
        
        return request.getAnalytics(param: param)
    }
}



