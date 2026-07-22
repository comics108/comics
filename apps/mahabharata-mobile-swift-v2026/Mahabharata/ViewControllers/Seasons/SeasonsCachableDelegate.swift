//
//  SeasonsCachableDelegate.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 17.09.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

import Foundation

protocol SeasonsCachableDelegate: AnyObject {
    func cache(_ seasons: [Season], _ completion: @escaping (Result<Bool, Error>) -> Void)
    func cached(_ completion: @escaping (Result<[Season], Error>) -> Void)
}
