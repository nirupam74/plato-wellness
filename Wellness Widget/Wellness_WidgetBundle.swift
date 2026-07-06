//
//  Wellness_WidgetBundle.swift
//  Wellness Widget
//
//  The widgets Plato Wellness offers on the home and lock screens.
//

import WidgetKit
import SwiftUI

@main
struct Wellness_WidgetBundle: WidgetBundle {
    var body: some Widget {
        WaterWidget()
        SummaryWidget()
    }
}
