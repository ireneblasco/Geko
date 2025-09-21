//
//  GekoWidgetsLiveActivity.swift
//  GekoWidgets
//
//  Created by Irenews on 9/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GekoWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GekoWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GekoWidgetsAttributes.self) { context in
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

extension GekoWidgetsAttributes {
    fileprivate static var preview: GekoWidgetsAttributes {
        GekoWidgetsAttributes(name: "World")
    }
}

extension GekoWidgetsAttributes.ContentState {
    fileprivate static var smiley: GekoWidgetsAttributes.ContentState {
        GekoWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GekoWidgetsAttributes.ContentState {
         GekoWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GekoWidgetsAttributes.preview) {
   GekoWidgetsLiveActivity()
} contentStates: {
    GekoWidgetsAttributes.ContentState.smiley
    GekoWidgetsAttributes.ContentState.starEyes
}
