//
//  SeasonsCacher.swift
//  Mahabharata
//
//  Created by Aleksey Shevchenko on 17.09.2022.
//  Copyright © 2022 Iron Water Studio. All rights reserved.
//

import Foundation

class SeasonsCacher: SeasonsCachableDelegate {
    private let key = "Mahabharata.SeasonsCache"
    
    func cache(_ seasons: [Season], _ completion: @escaping (Result<Bool, Error>) -> Void) {
        let encoder = JSONEncoder()
        do {
            let encodedSeasons = try encoder.encode(seasons)
            UserDefaults.standard.set(encodedSeasons, forKey: key)
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func cached(_ completion: @escaping (Result<[Season], Error>) -> Void) {
        if let data = UserDefaults.standard.value(forKey: key) as? Data {
            let decoder = JSONDecoder()
            do {
                let decodedSeasons = try decoder.decode([Season].self, from: data)
                completion(.success(decodedSeasons))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
