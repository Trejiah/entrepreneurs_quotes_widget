//
//  BusinessMindsetWidgetBundle.swift
//  BusinessMindsetWidget
//
//  Created by Gabrielle Jarmuzek on 10/11/2025.
//

import WidgetKit
import SwiftUI

@main
struct BusinessMindsetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BusinessMindsetWidget()
        if #available(iOSApplicationExtension 18.0, *) {
            BusinessMindsetWidgetControl()
        }
        if #available(iOSApplicationExtension 16.1, *) {
            BusinessMindsetWidgetLiveActivity()
        }
    }
}
