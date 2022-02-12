//
// String+Extension.swift
//
// Created by jljdavidson on 4/7/17
// Copyright (c) Copper Creek Software, LLC. All rights reserved.
//

import Foundation

extension String {
    static func className(_ aClass: AnyClass) -> String {
        return NSStringFromClass(aClass).components(separatedBy: ".").last!
    }

    func substring(_ from: Int) -> String {
        return self.substring(from: self.index(self.startIndex, offsetBy: from))
    }

    var length: Int {
        return self.count
    }

    func substringAfterLast(_ c: Character) -> String {
        if let index = self.lastIndex(of: c) {
            return String(self.suffix(from: index).dropFirst())
        }
        return self
    }

    func camelCaseToWords() -> String {
        unicodeScalars.dropFirst().reduce(String(prefix(1))) {
            CharacterSet.uppercaseLetters.contains($1)
                    ? $0 + " " + String($1)
                    : $0 + String($1)
        }
    }
}
