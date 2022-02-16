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

	func flatten() -> [(String, String)] {
		var toArr: [(String, String)] = []
		flatJson(self, array: &toArr)
		toArr.sort { tuple, tuple2 in
			tuple.0 < tuple2.0
		}
		return toArr
	}

	private func flatJson(_ json: JSON, label: String = "", array: inout [(String, String)]) {
		for (k, v) in json {
			if (v.type == .dictionary) {
				flatJson(v, label: k.camelCaseToWords().capitalized, array: &array)
			} else if (v.type == .array) {
				for a in v.arrayValue {
					if(a.type == .array || a.type == .dictionary) {
						flatJson(a, label: k.camelCaseToWords().capitalized, array: &array)
					} else {
						array.append((k.camelCaseToWords().capitalized, a.stringValue))
					}
				}
			} else {
				array.append((k.camelCaseToWords().capitalized, v.stringValue))
			}
		}
	}

}