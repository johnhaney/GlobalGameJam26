//
//  IntroView.swift
//  GlobalGameJam26
//
//  Created by John Haney on 2/1/26.
//

import SwiftUI
import Combine

enum Navigation: Hashable {
    case intro
    case game
    case outro
}

struct IntroView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var gameEngine: GameEngine
    @Binding var path: NavigationPath
    @State var hero = Helmet(position: CGPoint(x: 100, y: 44))
    @State var helmet = Helmet(position: CGPoint(x: 144, y: 44))
    @State var portal = Portal(position: CGPoint(x: 140, y: 43))
    @State var timer = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()
    @State var time: TimeInterval = 0
    @State var lastUpdateTime: Date?
    @State var introState: IntroState = .walk
    @State var shouldBackup: Bool = false
    
    enum IntroState {
        case walk
        case pickupHelmet
        case portal
        case done
    }

    var body: some View {
        ZStack {
            Canvas(renderer: { context, size in
                let time = self.time
                let scale = size.height/80.0
                if let symbol = context.resolveSymbol(id: "bg") {
                    let bgScale = CGSize(width: size.width * scale, height: size.height * scale)
                    context.draw(symbol, in: CGRect(origin: .zero, size: size))
                }
                
                switch introState {
                case .walk:
                    break
                case .pickupHelmet:
                    break
                case .portal, .done:
                    if let symbol = context.resolveSymbol(id: "portal") {
                        let position = CGPoint(
                            x: portal.position.x * scale,
                            y: portal.position.y * scale)
                        context.draw(symbol, in: portal.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                    }
                }
                
                if let symbol = context.resolveSymbol(id: "hero") {
                    let position = CGPoint(
                        x: hero.position.x * scale,
                        y: hero.position.y * scale)
                    context.draw(symbol, in: hero.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                }
                
                switch introState {
                case .walk:
                    if let symbol = context.resolveSymbol(id: "helmetDown") {
                        let position = CGPoint(
                            x: helmet.position.x * scale,
                            y: helmet.position.y * scale)
                        context.draw(symbol, in: helmet.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                    }
                case .pickupHelmet:
                    if let symbol = context.resolveSymbol(id: "helmet") {
                        let position = CGPoint(
                            x: helmet.position.x * scale,
                            y: helmet.position.y * scale)
                        context.draw(symbol, in: helmet.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                    }
                case .portal, .done:
                    if let symbol = context.resolveSymbol(id: "helmet") {
                        let position = CGPoint(
                            x: helmet.position.x * scale,
                            y: helmet.position.y * scale)
                        context.draw(symbol, in: helmet.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                    }
                }
            }, symbols: {
                Image("hero_regular").resizable().frame(width: 100, height: 100).tag("hero")
                Image("helmet").resizable().frame(width: 100, height: 100).tag("helmet")
                Image("helmet_down").resizable().frame(width: 100, height: 100).tag("helmetDown")
                Image("intro_bg").resizable().frame(width: 2000, height: 800).tag("bg")
                Image("portal_unlocked").resizable().frame(width: 100, height: 100).tag("portal")
            })
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                update()
                self.time = Date().timeIntervalSinceNow
            }
        }
    }
    
    @State var pickupStartTime: Date = Date()
    
    func update() {
        guard let lastUpdateTime else {
            lastUpdateTime = Date()
            return
        }
        let now = Date()
        let interval = now.timeIntervalSince(lastUpdateTime)
        self.lastUpdateTime = now
        
        switch introState {
        case .walk:
            hero.position.x += 10 * interval
            if hero.boundingBox.offsetBy(dx: hero.position.x, dy: hero.position.y).intersects(helmet.boundingBox.offsetBy(dx: helmet.position.x, dy: helmet.position.y)) {
                introState = .pickupHelmet
                pickupStartTime = now
            }
        case .pickupHelmet:
            helmet.position.y -= 10 * interval
            
            let time = now.timeIntervalSince(pickupStartTime)
            
            // 144, 44
            helmet.position.x = 144 - 15 * time * time
            helmet.position.y = 44 + 0.8 * (7 * time * ( -time) + 5) * (7 * time * ( -time) + 5) - 20
            
            if time > 1.1 {
                introState = .portal
            }
        case .portal:
            gameEngine.playSound(.portalTransition)
            introState = .done
        case .done:
            path.removeLast()
            path.append(Navigation.game)
        }
    }
}

struct Helmet: MovingGameObject {
    var id: any Hashable = "helmet"
    var frame: GameCharacterFrame = .arrow
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var direction: GameDirection = .right
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 20, height: 20)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 20, height: 20)
}

struct Portal: MovingGameObject {
    var id: any Hashable = "portal"
    var frame: GameCharacterFrame = .arrow
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var direction: GameDirection = .right
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
}
