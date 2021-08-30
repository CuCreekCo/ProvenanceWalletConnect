//
// JSON+Extension.swift
//
// Created by jljdavidson on 4/7/17
// Copyright (c) Copper Creek Software, LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
	mutating func appendIfArray(json: JSON) {
		if var arr = self.array {
			arr.append(json)
			self = JSON(arr);
		}
	}

	mutating func appendIfDictionary(key: String, json: JSON) {
		if var dict = self.dictionary {
			dict[key] = json;
			self = JSON(dict);
		}
	}
}