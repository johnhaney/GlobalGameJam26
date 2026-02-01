//
//  CreditsView.swift
//  GlobalGameJam26
//
//  Created by John Haney on 2/1/26.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack {
            Text("Credits")
                .font(.largeTitle)
            
            Grid {
                GridRow(alignment: .firstTextBaseline) {
                    Text("🐲 Malcolm Haney")
                        .font(.title2.bold())
                        .gridColumnAlignment(.trailing)
                    Text("Art, Animation, Game Design")
                        .font(.title2)
                        .gridColumnAlignment(.leading)
                }
                GridRow(alignment: .firstTextBaseline) {
                    Text("🎧 Everett Haney")
                        .font(.title2.bold())
                    Text("Sound, Art, Game Design")
                        .font(.title2)
                }
                GridRow(alignment: .firstTextBaseline) {
                    Text("👨‍💻 John Haney")
                        .font(.title2.bold())
                    Text("Programming, Project Manager,\nGame Design")
                        .font(.title2)
                }
            }
        }
    }
}

#Preview {
    CreditsView()
}
