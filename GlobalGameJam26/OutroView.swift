//
//  OutroView.swift
//  GlobalGameJam26
//
//  Created by John Haney on 2/1/26.
//

import SwiftUI
import Combine

struct OutroView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var gameEngine: GameEngine
    @Binding var path: NavigationPath
    @State var hero = Helmet(position: CGPoint(x: 144, y: 44))
    @State var portal = Portal(position: CGPoint(x: 140, y: 43))
    @State var timer = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()
    @State var time: TimeInterval = 0
    @State var lastUpdateTime: Date?
    @State var outroState: OutroState = .walk
    @State var outroDone: Bool = false
    @State var shouldBackup: Bool = false
    
    enum OutroState {
        case walk
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
                
                if let symbol = context.resolveSymbol(id: "portal") {
                    let position = CGPoint(
                        x: portal.position.x * scale,
                        y: portal.position.y * scale)
                    context.draw(symbol, in: portal.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                }
                
                if let symbol = context.resolveSymbol(id: "hero") {
                    let position = CGPoint(
                        x: hero.position.x * scale,
                        y: hero.position.y * scale)
                    context.draw(symbol, in: hero.drawRect.applying(.init(scaleX: scale, y: scale)).offsetBy(dx: position.x, dy: position.y))
                }
            }, symbols: {
                Image("hero_victory").resizable().frame(width: 100, height: 100).tag("hero")
                Image("outro_bg").resizable().frame(width: 2000, height: 800).tag("bg")
                Image("entry").resizable().frame(width: 100, height: 100).tag("portal")
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
        
        switch outroState {
        case .walk:
            hero.position.x += 10 * interval
            if hero.position.x > 2000 {
                outroState = .done
                while (!path.isEmpty) {
                    path.removeLast()
                }
            }
        case .done:
            break
        }
    }
}
