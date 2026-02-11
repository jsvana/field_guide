//
//  AppState.swift
//  FieldGuide
//

import SwiftUI

@Observable final class AppState {
    var selectedTab: Int = 0
    var pendingRadioID: String?
}
