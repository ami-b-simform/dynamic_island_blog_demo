//
//  RideTrackerWidgetBundle.swift
//  RideTrackerWidget
//
//  Created by Ami Borsadia on 17/03/26.
//

import WidgetKit
import SwiftUI

@main
struct RideTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RideTrackerWidget()
        RideTrackerLiveActivity()
    }
}
