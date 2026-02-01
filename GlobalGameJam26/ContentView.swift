//
//  ContentView.swift
//  GlobalGameJam26
//
//  Created by John Haney on 2/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var gameEngine: GameEngine = GameEngine(level: .level1)
    @State var path: NavigationPath = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                Text("Time Jump")
                    .font(.largeTitle)
                    .padding()
                Button("Play") {
                    path.append(Navigation.intro)
                }
                .font(.title)
                .buttonStyle(.borderedProminent)
                HStack {
                    Button("Level 1") {
                        gameEngine.load(level: .level1)
                    }
                    Button("Level 2") {
                        gameEngine.load(level: .level2)
                    }
                    Button("Level 3") {
                        gameEngine.load(level: .level3)
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        NavigationLink("Credits") {
                            CreditsView()
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                gameEngine.soundEngine.music = .menu
                gameEngine.soundEngine.startLooping()
            }
            .navigationDestination(for: Navigation.self) { navItem in
                switch navItem {
                case .intro:
                    IntroView(gameEngine: gameEngine, path: $path)
                case .game:
                    GameView(gameEngine: gameEngine, path: $path)
                        .onAppear {
                            gameEngine.soundEngine.music = .world1
                            gameEngine.soundEngine.startLooping()
                        }
                        .onDisappear {
                            gameEngine.soundEngine.music = .menu
                            gameEngine.soundEngine.startLooping()
                        }
                case .outro:
                    OutroView(gameEngine: gameEngine, path: $path)
                }
            }
        }.navigationBarHidden(true)
    }
}
