//
//  MessagesView.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/10/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI
import Combine

struct MessagesView: View {
    @ObservedObject var universe: Universe

    // Safe optional access - won't crash if delegate is nil or wrong type
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(self.universe.recentMessages, id: \.self) { message in
                Text(message)
                    .font(.headline)
            }
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe

    MessagesView(universe: universe)
}
#endif
