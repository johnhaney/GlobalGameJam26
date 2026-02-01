//
//  GameView.swift
//  GlobalGameJam26
//
//  Created by John Haney on 1/30/26.
//

import SwiftUI
import Combine
import GameController

struct GameView: View {
    @ObservedObject var gameEngine: GameEngine
    @Binding var path: NavigationPath
    @State var timer = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()
    @State var time: TimeInterval = 0
    @Environment(\.dismiss) var dismiss
    @State var controller: GCVirtualController = {
        var config = GCVirtualController.Configuration()
        config.elements = [
            GCInputButtonA,
            GCInputButtonB,
            GCInputButtonX,
            GCInputButtonY,
            GCInputLeftThumbstick]
        let controller = GCVirtualController(configuration: config)
        return controller
    }()
    
    var body: some View {
        ZStack {
            Canvas(renderer: { context, size in
                let time = self.time
                let scale = min(size.width/CGFloat(gameEngine.gameState.level.count), size.height/CGFloat(gameEngine.gameState.level.count))
                
                if let symbol = context.resolveSymbol(id: LevelSquare.empty) {
                    context.draw(symbol, in: CGRect(origin: .zero, size: size))
                }
                
                if gameEngine.gameState.player.position.x > 7 {
                    context.transform = context.transform.translatedBy(x: -scale * (gameEngine.gameState.player.position.x-7), y: 0)
                }
                let visibleWidth = Int(ceil(size.width / scale))
                let visibleHeight = Int(ceil(size.height / scale))
                
                for row in 0..<gameEngine.gameState.level.count {
                    for col in 0..<gameEngine.gameState.level[row].count {
                        let fill: Color
                        switch gameEngine.gameState.level[row][col] {
                        case .empty: continue
                        case .ground:
                            if let symbol = context.resolveSymbol(id: LevelSquare.ground) {
                                context.draw(symbol, in: CGRect(origin: CGPoint(x: CGFloat(col) * scale, y: CGFloat(row) * scale), size: CGSize(width: scale, height: scale)))
                            }
                            continue
                        case .spike:
                            if let symbol = context.resolveSymbol(id: LevelSquare.spike) {
                                context.draw(symbol, in: CGRect(origin: CGPoint(x: CGFloat(col) * scale, y: CGFloat(row) * scale), size: CGSize(width: scale, height: scale * 2)))
                            }
                            continue
                        case .ceilingSpike:
                            if let symbol = context.resolveSymbol(id: LevelSquare.ceilingSpike) {
                                context.draw(symbol, in: CGRect(origin: CGPoint(x: CGFloat(col) * scale, y: CGFloat(row) * scale), size: CGSize(width: scale, height: scale * 2)))
                            }
                            continue
                        case .fakeBlock:
                            if let symbol = context.resolveSymbol(id: LevelSquare.ground) {
                                context.draw(symbol, in: CGRect(origin: CGPoint(x: CGFloat(col) * scale, y: CGFloat(row) * scale), size: CGSize(width: scale, height: scale)))
                            }
                            continue
                        case .invisibleBlock: continue
                        case .goal: fill = gameEngine.gameState.hasKey ? .yellow : .black
                        }
//                        let path = Path(roundedRect: CGRect(origin: CGPoint(x: CGFloat(col) * scale, y: CGFloat(row) * scale), size: CGSize(width: scale, height: scale)), cornerSize: CGSize(width: scale/20, height: scale/20))
//                        context.fill(path, with: .color(fill))
                    }
                }
                
                for item in gameEngine.gameState.items {
                    if let symbol = context.resolveSymbol(id: item.id) {
                        let position = CGPoint(
                            x: item.position.x * scale,
                            y: item.position.y * scale)
                        context.draw(symbol, in: item.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                    }
                }
                
                for enemy in gameEngine.gameState.enemies {
                    if let symbol = context.resolveSymbol(id: enemy.frame) {
                        let position = CGPoint(
                            x: enemy.position.x * scale,
                            y: enemy.position.y * scale)
                        context.draw(symbol, in: enemy.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
//                        let path = Path(roundedRect: enemy.boundingBox.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y), cornerSize: .zero)
//                        context.stroke(path, with: .color(.orange))
//                        do {
//                            let path = Path(roundedRect: enemy.attackBox.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y), cornerSize: .zero)
//                            context.stroke(path, with: .color(.pink))
//                        }
                    }
                }
                
                let player = gameEngine.gameState.player
                let position = CGPoint(
                    x: player.position.x * scale,
                    y:
                        player.position.y * scale)
                if let symbol = context.resolveSymbol(id: player.frame) {
                    context.draw(symbol, in: player.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                }
//                do {
//                    let path = Path(roundedRect: player.boundingBox.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y), cornerSize: .zero)
//                    context.stroke(path, with: .color(.blue))
//                }
//                do {
//                    let path = Path(roundedRect: player.attackBox.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y), cornerSize: .zero)
//                    context.stroke(path, with: .color(.pink))
//                }
            }, symbols: {
                Image("ground").resizable().frame(width: 100, height: 100).tag(LevelSquare.ground)
                Image("spikes").resizable().frame(width: 100, height: 200).offset(y: -100).tag(LevelSquare.spike)
                Image("ceiling_spikes").resizable().frame(width: 100, height: 200).tag(LevelSquare.ceilingSpike)
                Image("background").resizable().frame(width: 2000, height: 667).tag(LevelSquare.empty)
                Image("hero-blocking").resizable().frame(width: 2000, height: 667).tag(GameCharacterFrame.heroBlocking)
                Image("hero-thrust1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroThrust1)
                Image("hero-thrust2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroThrust2)
                Image("hero-thrust3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroThrust3)
                Image("hero-new1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroNewWalk1)
                Image("hero-new2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroNewWalk2)
                Image("hero-new3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroNewWalk3)
                Image("hero-walk1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroWalk1)
                Image("hero-walk2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroWalk2)
                Image("hero-walk3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroWalk3)
                Image("hero-attack1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroAttack1)
                Image("hero-attack2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroAttack2)
                Image("hero-attack3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.heroAttack3)
                Image("archer1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.archerAttack1)
                Image("archer2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.archerAttack2)
                Image("archer3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.archerAttack3)
                Image("boss1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.bossWalk1)
                Image("boss2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.bossWalk2)
                Image("boss3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.bossWalk3)
                Image("boss-attack1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.bossAttack1)
                Image("boss-attack2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.bossAttack2)
                Image("goblin1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.goblinWalk1)
                Image("goblin2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.goblinWalk2)
                Image("goblin3").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.goblinWalk3)
                Image("goblin-attack1").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.goblinAttack1)
                Image("goblin-attack2").resizable().frame(width: 500, height: 500).tag(GameCharacterFrame.goblinAttack2)
                Image("key").resizable().frame(width: 100, height: 100).tag(LevelPiece.key)
                Image("entry").resizable().frame(width: 100, height: 100).tag(LevelPiece.entry)
                Image("portal_locked").resizable().frame(width: 100, height: 100).tag(LevelPiece.exitLocked)
                Image("portal_unlocked").resizable().frame(width: 100, height: 100).tag(LevelPiece.exitUnlocked)
                Image("sword").resizable().frame(width: 100, height: 100).tag(LevelPiece.sword)
            })
            .frame(minWidth: 300, minHeight: 300)
            .ignoresSafeArea()
            HUDView()
        }
        .onReceive(timer) { time in
            gameEngine.update()
            self.time = time.timeIntervalSinceNow
        }
        .onChange(of: gameEngine.gameState.hasSword, { oldValue, newValue in
            controller.updateConfiguration(forElement: GCInputButtonB, configuration: { config in
                config.isHidden = !newValue
                return config
            })
            controller.updateConfiguration(forElement: GCInputButtonX, configuration: { config in
                config.isHidden = !newValue
                return config
            })
            controller.updateConfiguration(forElement: GCInputButtonY, configuration: { config in
                config.isHidden = !newValue
                return config
            })
        })
        .onChange(of: gameEngine.isGameOver, { oldValue, newValue in
            if newValue {
                controller.disconnect()
            } else {
                Task {
                    try await controller.connect()
                    gameEngine.gamepad = controller.controller?.extendedGamepad
                }
            }
        })
        .onChange(of: gameEngine.isGameWon, { oldValue, newValue in
            if newValue {
                path.removeLast()
                path.append(Navigation.outro)
            }
        })
        .onAppear {
            Task {
                controller.updateConfiguration(forElement: GCInputButtonB, configuration: { config in
                    config.isHidden = !gameEngine.gameState.hasSword
                    return config
                })
                controller.updateConfiguration(forElement: GCInputButtonX, configuration: { config in
                    config.isHidden = !gameEngine.gameState.hasSword
                    return config
                })
                controller.updateConfiguration(forElement: GCInputButtonY, configuration: { config in
                    config.isHidden = !gameEngine.gameState.hasSword
                    return config
                })
                try await controller.connect()
                gameEngine.gamepad = controller.controller?.extendedGamepad
            }
        }
        .onDisappear {
            controller.disconnect()
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
    }
    
    @ViewBuilder func HUDView() -> some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        gameEngine.isPaused.toggle()
                    } label: {
                        Image(systemName: "pause.circle")
                    }
                    Spacer()
                    HealthView(health: $gameEngine.playerHealth)
                }
                Spacer()
            }
            if gameEngine.isGameOver {
                Color.red.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    Text("Game Over")
                        .font(.largeTitle.bold())
                    Button("Play Again") {
                        gameEngine.load(level: gameEngine.level)
                    }
                }
            } else if gameEngine.isPaused {
                Color.gray.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    Text("Pause")
                        .font(.largeTitle.bold())
                    HStack {
                        Button("Resume") {
                            gameEngine.isPaused.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Main Menu (Quit)", role: .destructive) {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    struct HealthView: View {
        @Binding var health: CGFloat
        
        var body: some View {
            ProgressView("Health", value: health, total: 100)
                .tint(health < 20 ? Color.red : (health < 60 ? Color.yellow : Color.green))
                .frame(maxWidth: 100)
        }
    }
}


extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x,
                y: lhs.y + rhs.y)
    }
}
