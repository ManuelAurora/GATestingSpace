//
//  BindableType.swift
//  TestingSpace
//
//  Created by Manuel Aurora on 18.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Foundation
import Cocoa

protocol BindableType
{
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
    func bindViewModel()
}

extension BindableType where Self: NSViewController
{
    mutating func bindTo(viewModel: ViewModelType) {
        self.viewModel = viewModel
        loadView()
        bindViewModel()
    }
}

