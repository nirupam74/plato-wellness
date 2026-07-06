//
//  Units.swift
//  Wellness App
//
//  Display conversions. Everything is stored in metric internally, these
//  helpers convert only at the presentation edge (spec section 4).
//

import Foundation

enum Units {
    // Weight
    static func kgToLb(_ kg: Double) -> Double { kg * 2.2046226218 }
    static func lbToKg(_ lb: Double) -> Double { lb / 2.2046226218 }

    // Length
    static func cmToIn(_ cm: Double) -> Double { cm / 2.54 }
    static func inToCm(_ inch: Double) -> Double { inch * 2.54 }

    // Volume
    static func mlToFloz(_ ml: Double) -> Double { ml / 29.5735 }

    /// Display a weight in the user's preferred system.
    static func displayWeight(kg: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:   String(format: "%.1f kg", kg)
        case .imperial: String(format: "%.1f lb", kgToLb(kg))
        }
    }

    /// Display a body length (height, waist, etc).
    static func displayLength(cm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:   String(format: "%.0f cm", cm)
        case .imperial: String(format: "%.1f in", cmToIn(cm))
        }
    }
}
