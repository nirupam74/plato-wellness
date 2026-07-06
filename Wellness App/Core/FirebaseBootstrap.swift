//
//  FirebaseBootstrap.swift
//  Wellness App
//
//  Configures Firebase and App Check at launch. App Check must have its provider
//  factory set BEFORE FirebaseApp.configure().
//
//  Debug builds (including the simulator, where App Attest is unavailable) use
//  the debug provider, which prints a debug token to the console on first launch.
//  Copy that token into Firebase console -> App Check -> your app -> Manage debug
//  tokens so the simulator can call the App Check enforced functions.
//  Release builds use App Attest.
//

import Foundation
import FirebaseCore
import FirebaseAppCheck

final class WellnessAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}

enum FirebaseBootstrap {
    static func configure() {
        AppCheck.setAppCheckProviderFactory(WellnessAppCheckFactory())
        FirebaseApp.configure()
    }
}
