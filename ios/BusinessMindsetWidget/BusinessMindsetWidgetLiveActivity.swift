//
//  BusinessMindsetWidgetLiveActivity.swift
//  BusinessMindsetWidget
//
//  Created by Gabrielle Jarmuzek on 10/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 16.1, *)
struct BusinessMindsetWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

@available(iOSApplicationExtension 16.1, *)
struct BusinessMindsetWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusinessMindsetWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
extension BusinessMindsetWidgetAttributes {
    fileprivate static var preview: BusinessMindsetWidgetAttributes {
        BusinessMindsetWidgetAttributes(name: "World")
    }
}

@available(iOSApplicationExtension 16.1, *)
extension BusinessMindsetWidgetAttributes.ContentState {
    fileprivate static var smiley: BusinessMindsetWidgetAttributes.ContentState {
        BusinessMindsetWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BusinessMindsetWidgetAttributes.ContentState {
         BusinessMindsetWidgetAttributes.ContentState(emoji: "🤩")
     }
}

