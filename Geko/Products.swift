//
//  Products.swift
//  Geko
//
//  Product IDs for Geko Plus subscriptions. Must match App Store Connect exactly.
//

import Foundation

enum Products {
    static let monthlyID = "com.irenews.geko.plus.monthly"
    static let annualID = "com.irenews.geko.plus.annual"
    static let lifetimeID = "com.irenews.geko.plus.lifetime"

    static var allIDs: [String] {
        [monthlyID, annualID, lifetimeID]
    }
}
