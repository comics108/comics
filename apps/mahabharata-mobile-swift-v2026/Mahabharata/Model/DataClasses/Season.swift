//
//  Season.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 2020.
//  Copyright (c) 2020 Iron Water Studio. All rights reserved.
//

import Foundation

extension Season: Equatable {
    static func == (lhs: Season, rhs: Season) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Season: Codable {}

struct Season {

	var id: Int
	var name: String
	var image: String
	var product: String
	var order: Int
	var episodes: [Episode]
	// Local property; comes from AppStore
	var price: String

	init(id: Int, name: String, image: String, product: String, order: Int, episodes: [Episode]) {
		self.id = id
		self.name = name
		self.image = image
		self.product = product
		self.order = order
		self.episodes = episodes
		self.price = ""
	}

	init() {
		self.init(id: Int(), name: String(), image: String(), product: String(), order: Int(), episodes: [Episode]())
	}

}

extension Season: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"Name: \(name)",
			"Image: \(image)",
			"Product: \(product)",
			"Order: \(order)",
			"Episodes: \(episodes)"
			].joined(separator: ", ")
	}
}

extension Season {
	/**
		Example for closure:
		 	(success: @escaping (Season?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Season.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Season.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Season? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Season field \"data\" is not dictionary type"
		}
		
		var model = Season()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Season field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let name: String = try? String.parse(json["name"], model.name) else {
			throw "Season field \"name\" has wrong value \"\(String(describing: json["name"]))\" for type \"String\""
		}
		model.name = name

		guard let image: String = try? String.parse(json["image"], model.image) else {
			throw "Season field \"image\" has wrong value \"\(String(describing: json["image"]))\" for type \"String\""
		}
		model.image = image

		guard let product: String = try? String.parse(json["product"], model.product) else {
			throw "Season field \"product\" has wrong value \"\(String(describing: json["product"]))\" for type \"String\""
		}
		model.product = product

		guard let order: Int = try? Int.parse(json["order"], model.order) else {
			throw "Season field \"order\" has wrong value \"\(String(describing: json["order"]))\" for type \"Int\""
		}
		model.order = order

		do {
			if let episodes: [Episode] = try Episode.array(json["episodes"]) {
				model.episodes = episodes
			}
		} catch { throw "Season field \"episodes\" has wrong value \"\(String(describing: json["episodes"]))\" for type \"[Episode]\"" }

		//Add prefix for short product ID
		if !String.isNilOrWhiteSpace(product) && !product.contains("."), let bundleId = Bundle.main.bundleIdentifier {
			model.product = bundleId + "." + product
		}

		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Season]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Season.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Season.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Season]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Season field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Season.parse) else { throw "Season field \"data\" contains items with unexpected format" }
		
		return result
	}
}
