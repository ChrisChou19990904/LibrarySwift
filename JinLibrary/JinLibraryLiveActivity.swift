//
//  JinLibraryLiveActivity.swift
//  JinLibrary
//
//  Created by fcuiecs on 2025/10/14.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct JinLibraryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct JinLibraryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JinLibraryAttributes.self) { context in
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

extension JinLibraryAttributes {
    fileprivate static var preview: JinLibraryAttributes {
        JinLibraryAttributes(name: "World")
    }
}

extension JinLibraryAttributes.ContentState {
    fileprivate static var smiley: JinLibraryAttributes.ContentState {
        JinLibraryAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: JinLibraryAttributes.ContentState {
         JinLibraryAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: JinLibraryAttributes.preview) {
   JinLibraryLiveActivity()
} contentStates: {
    JinLibraryAttributes.ContentState.smiley
    JinLibraryAttributes.ContentState.starEyes
}
