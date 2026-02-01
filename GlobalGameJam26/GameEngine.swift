//
//  GameEngine.swift
//  GlobalGameJam26
//
//  Created by John Haney on 1/30/26.
//

import SwiftUI
import Combine
import GameController

protocol GameObject {
    var id: any Hashable { get }
    var position: CGPoint { get set }
    var boundingBox: CGRect { get set }
    var drawRect: CGRect { get set }
}

protocol LevelPieceContaining: GameObject {
    var piece: LevelPiece { get }
}

protocol MovingGameObject: GameObject {
    var frame: GameCharacterFrame { get set }
    var velocity: CGVector { get set }
    var acceleration: CGVector { get set }
    var direction: GameDirection { get set }
    mutating func update(_ gameState: GameState, interval: TimeInterval)
    mutating func basicUpdate(interval: TimeInterval)
}

enum GameDirection {
    case left
    case right
}

protocol AttackingGameObject: MovingGameObject {
    var attackBox: CGRect { get set }
    var health: CGFloat { get set }
    var attackStrength: CGFloat { get }
    var attackCooldown: TimeInterval? { get set }
}

extension AttackingGameObject {
    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        basicUpdate(interval: interval)
    }
    
    mutating func basicUpdate(interval: TimeInterval) {
        velocity = CGVector(dx: velocity.dx + acceleration.dx * interval,
                            dy: velocity.dy + acceleration.dy * interval)
        position = CGPoint(x: position.x + velocity.dx * interval,
                           y: position.y + velocity.dy * interval)
        if let attackCooldown {
            if attackCooldown - interval <= 0 {
                self.attackCooldown = nil
            } else {
                self.attackCooldown = attackCooldown - interval
            }
        }
    }
}

extension MovingGameObject {
    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        basicUpdate(interval: interval)
    }
    
    mutating func basicUpdate(interval: TimeInterval) {
        velocity = CGVector(dx: velocity.dx + acceleration.dx * interval,
                            dy: velocity.dy + acceleration.dy * interval)
        position = CGPoint(x: position.x + velocity.dx * interval,
                           y: position.y + velocity.dy * interval)
    }
}

struct GamePlayer: AttackingGameObject {
    var id: any Hashable { GameCharacter.hero }
    var frame: GameCharacterFrame = .heroNewWalk1
    let frameRate: CGFloat = 0.33
    var position: CGPoint
    var health: CGFloat = 100
    let attackStrength: CGFloat = 20
    var attackCooldown: TimeInterval? = nil
    var direction: GameDirection = .right
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var boundingBox: CGRect = CGRect(x: 0.1, y: -0.55, width: 0.8, height: 1.55)
    var attackBox: CGRect = CGRect(x: 0.9, y: -0.7, width: 0.8, height: 1.7)
    var drawRect: CGRect = CGRect(x: -2, y: -2.25, width: 5, height: 5)
    var timing: TimeInterval = 0

    var walkFrames: [GameCharacterFrame] = [.heroWalk1, .heroWalk2, .heroWalk3]
    var newWalkFrames: [GameCharacterFrame] = [.heroNewWalk1, .heroNewWalk2, .heroNewWalk3]
    var attackFrames: [GameCharacterFrame] = [.heroAttack1, .heroAttack2, .heroAttack3]
    var thrustFrames: [GameCharacterFrame] = [.heroThrust1, .heroThrust2, .heroThrust3]
    
    var animation: PlayerAnimation = .none
    var animationStart: (timing: TimeInterval, position: CGPoint)?
    
    enum PlayerAnimation {
        case none
        case attack
        case thrust
    }

    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        timing += interval

        if let animationStart,
           animation != .none {
            let animationTime = timing - animationStart.timing
            switch animation {
            case .none:
                break
            case .attack:
                let attackDuration = 0.5
                acceleration.dx = 0
                velocity.dx = 0
                if animationTime < attackDuration {
                    frame = attackFrames[Int(animationTime / (attackDuration / CGFloat(attackFrames.count))) % attackFrames.count]
                } else {
                    self.animation = .none
                    self.animationStart = nil
                }
            case .thrust:
                let thrustDuration = 1.0
                acceleration.dx = 0
                velocity.dx = 0
                if animationTime < thrustDuration {
                    let offset = thrustOffsetX(animationStart.position, animationTime)
                    self.position.x = animationStart.position.x + offset
                    self.velocity.dx = -offset
                    self.acceleration.dx = 0
                    frame = thrustFrames[Int(animationTime / (thrustDuration / CGFloat(thrustFrames.count))) % thrustFrames.count]
                } else {
                    self.animation = .none
                    self.animationStart = nil
                }
            }
        }
        basicUpdate(interval: interval)
        if animation == .none {
            if gameState.isBlocking {
                frame = .heroBlocking
            } else if gameState.hasSword {
                if velocity.dx != 0 {
                    frame = walkFrames[Int(timing / frameRate) % walkFrames.count]
                } else {
                    frame = walkFrames[0]
                }
            } else {
                if velocity.dx != 0 {
                    frame = newWalkFrames[Int(timing / frameRate) % walkFrames.count]
                } else {
                    frame = newWalkFrames[0]
                }
            }
        }
    }
    
    func thrustOffsetX(_ startPosition: CGPoint, _ time: TimeInterval) -> CGFloat {
        let offset: CGFloat
        if time <= 0 {
            offset = 0
        } else if time >= 1 {
            offset = 1
        } else {
            offset = (5 * time * time - 2 * time) / 3
        }
        
        return offset
    }
    
    mutating func startThrustAnimation() {
        self.animationStart = (self.timing, self.position)
        self.animation = .thrust
    }
    
    mutating func startAttackAnimation() {
        self.animationStart = (self.timing, self.position)
        self.animation = .attack
    }
}

struct ArrowEnemy: AttackingGameObject {
    var id: any Hashable { GameCharacter.archer }
    var frame: GameCharacterFrame = .arrow
    var position: CGPoint
    var health: CGFloat = 1000
    let attackStrength: CGFloat = 10
    var attackCooldown: TimeInterval? = nil
    var direction: GameDirection = .left
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var boundingBox: CGRect
    var attackBox: CGRect
    var drawRect: CGRect
    
    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        acceleration = .zero
        basicUpdate(interval: interval)
    }
}

struct GoblinEnemy: AttackingGameObject {
    var id: any Hashable { GameCharacter.goblin }
    var frame: GameCharacterFrame = .goblinWalk1
    let frameRate: CGFloat = 0.33
    var position: CGPoint
    var health: CGFloat = 20
    let attackStrength: CGFloat = 10
    var attackCooldown: TimeInterval? = nil
    var direction: GameDirection = .left
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var boundingBox: CGRect
    var attackBox: CGRect
    var drawRect: CGRect
    var timing: TimeInterval = 0
    
    var walkFrames: [GameCharacterFrame] = [.goblinWalk1, .goblinWalk2, .goblinWalk3]
    var attackFrames: [GameCharacterFrame] = [.goblinAttack1, .goblinAttack2]
    
    init(position: CGPoint) {
        self.position = position
        self.boundingBox = CGRect(x: 0.2, y: -0.1, width: 0.6, height: 1.1)
        self.attackBox = CGRect(x: -0.5, y: -0.2, width: 0.7, height: 0.9)
        self.drawRect = CGRect(x: -0.35, y: -0.25, width: 1.25, height: 1.25)
    }
    
    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        timing += interval
        if gameState.player.position.y == position.y,
           abs(gameState.player.position.x - position.x) < 4,
           !boundingBox.offsetBy(dx: position.x, dy: position.y).intersects(gameState.player.boundingBox.offsetBy(dx: gameState.player.position.x, dy: gameState.player.position.y)) {
            // move toward the player
            velocity.dx = (gameState.player.position.x - position.x) / abs(gameState.player.position.x - position.x)
        } else {
            velocity.dx = 0
        }
        basicUpdate(interval: interval)

        if attackCooldown != nil {
            frame = attackFrames[Int(timing / frameRate) % attackFrames.count]
        } else if velocity.dx != 0 {
            frame = walkFrames[Int(timing / frameRate) % walkFrames.count]
        } else {
            frame = walkFrames[0]
        }
    }
}

struct ArcherEnemy: AttackingGameObject {
    var id: any Hashable { GameCharacter.archer }
    var frame: GameCharacterFrame = .archerAttack1
    let frameRate: CGFloat = 0.33
    var position: CGPoint
    var health: CGFloat = 30
    let attackStrength: CGFloat = 0
    var attackCooldown: TimeInterval? = nil
    var direction: GameDirection = .left
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var boundingBox: CGRect
    var attackBox: CGRect
    var drawRect: CGRect

    init(position: CGPoint) {
        self.position = position
        self.boundingBox = CGRect(x: 0.2, y: -0.1, width: 0.6, height: 1.1)
        self.attackBox = CGRect(x: 0.2, y: -0.1, width: 0.6, height: 1.1)
        self.drawRect = CGRect(x: -0.4, y: -0.75, width: 2, height: 2)
    }
    
    mutating func update(_ gameEngine: GameEngine, interval: TimeInterval) {
        basicUpdate(interval: interval)
        if attackCooldown == nil {
            if gameEngine.gameState.player.position.distance(to: position) < 9 {
                gameEngine.playSound(.arrowAttack)
//                gameEngine.arrowAttack(from: position)
                attackCooldown = 1.5
            }
        }
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        sqrt((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y))
    }
}

struct BossEnemy: AttackingGameObject {
    var id: any Hashable { GameCharacter.boss }
    var frame: GameCharacterFrame = .bossWalk1
    let frameRate: CGFloat = 0.33
    var position: CGPoint
    var health: CGFloat = 150
    let attackStrength: CGFloat = 30
    var attackCooldown: TimeInterval? = nil
    var direction: GameDirection = .left
    var velocity: CGVector = .zero
    var acceleration: CGVector = .zero
    var boundingBox: CGRect
    var attackBox: CGRect
    var drawRect: CGRect
    var timing: TimeInterval = 0
    
    var walkFrames: [GameCharacterFrame] = [.bossWalk1, .bossWalk2, .bossWalk3]
    var attackFrames: [GameCharacterFrame] = [.bossAttack1, .bossAttack2]

    init(position: CGPoint) {
        self.position = position
        self.boundingBox = CGRect(x: 0.2, y: -1.4, width: 1.0, height: 2.4)
        self.attackBox = CGRect(x: -1.3, y: -1.4, width: 2.0, height: 2.4)
        self.drawRect = CGRect(x: -1, y: -1.4, width: 2.5, height: 2.5)
    }
    
    mutating func update(_ gameState: GameState, interval: TimeInterval) {
        if gameState.player.position.y == position.y,
           abs(gameState.player.position.x - position.x) < 4,
           !boundingBox.offsetBy(dx: position.x, dy: position.y).intersects(gameState.player.boundingBox.offsetBy(dx: gameState.player.position.x, dy: gameState.player.position.y)) {
            // move toward the player
            velocity.dx = 1.5 * (gameState.player.position.x - position.x) / abs(gameState.player.position.x - position.x)
        } else {
            velocity.dx = 0
        }
        basicUpdate(interval: interval)
        timing += interval
        if attackCooldown != nil {
            frame = attackFrames[Int(timing / frameRate) % attackFrames.count]
        } else if velocity.dx != 0 {
            frame = walkFrames[Int(timing / frameRate) % walkFrames.count]
        } else {
            frame = walkFrames[0]
        }
    }
}

struct Entrance: LevelPieceContaining {
    var id: any Hashable { LevelPiece.entry }
    var piece: LevelPiece { .entry }
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
}

struct Goal: LevelPieceContaining {
    var id: any Hashable = LevelPiece.exitLocked
    var piece: LevelPiece = .exitLocked
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
}

struct PortalKey: LevelPieceContaining {
    var id: any Hashable { LevelPiece.key }
    var piece: LevelPiece { .key }
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
}

struct Sword: LevelPieceContaining {
    var id: any Hashable { LevelPiece.sword }
    var piece: LevelPiece { .sword }
    var position: CGPoint
    var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var drawRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
}

struct GameState {
    var player: GamePlayer
    var enemies: [AttackingGameObject]
    var hasKey: Bool = false
    var hasSword: Bool = false
    var isAttacking: Bool = false
    var isBlocking: Bool = false
    var items: [LevelPieceContaining]
    var level: [[LevelSquare]]
    var bossMusicStartX: CGFloat?
}

enum GameCharacter {
    case archer
    case boss
    case goblin
    case hero
}

enum LevelPiece {
    case entry
    case exitLocked
    case exitUnlocked
    case key
    case sword
}

enum LevelSquare {
    case empty
    case ground
    case spike
    case ceilingSpike
    case fakeBlock
    case invisibleBlock
    case goal
}

class GameEngine: ObservableObject {
    @Published var gameState: GameState
    @Published var playerHealth: CGFloat = 100 {
        didSet {
            if playerHealth <= 0 {
                gameOver()
            }
        }
    }
    var lastUpdate: Date?
    var gamepad: GCExtendedGamepad?
    var spikeDamageCooldown: TimeInterval? = nil
    var isGameOver = false
    var isGameWon = false
    var isPaused = false
    let gamepadScale: CGFloat = 5
    var level: GameLevel

    let soundEngine: SoundEngine

    init(level: GameLevel) {
        self.level = level
        self.playerHealth = 100
        self.lastUpdate = nil
        self.spikeDamageCooldown = nil
        self.gameState = Self.gameState(for: level)
        self.soundEngine = SoundEngine()
    }
    
    static func gameState(for gameLevel: GameLevel) -> GameState {
        let rows: [[Character]] = gameLevel.rawValue.split(separator: "\n").map(Array.init)
        var position: CGPoint = CGPoint(x: .zero, y: 1)
        var enemies: [AttackingGameObject] = []
        var items: [LevelPieceContaining] = []
        let columns: Int = rows.map(\.count).max() ?? rows.count
        var level = Array(repeating: Array(repeating: LevelSquare.empty, count: columns), count: rows.count)
        var hasSword = true
        var bossMusicStartX: CGFloat? = nil
        for row in rows.indices {
            for col in rows[row].indices {
                switch rows[row][col] {
                case " ": break
                case "P":
                    items.append(Entrance(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                    position = CGPoint(x: CGFloat(col), y: CGFloat(row))
                case "K": items.append(PortalKey(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "-": level[row][col] = .ground
                case "^": level[row][col] = .spike
                case "v": level[row][col] = .ceilingSpike
                case "F": level[row][col] = .fakeBlock
                case "O": level[row][col] = .ground
                case "I": level[row][col] = .invisibleBlock
                case "W":
                    hasSword = false
                    items.append(Sword(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "E": items.append(Goal(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "B": enemies.append(GoblinEnemy(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "A": enemies.append(ArcherEnemy(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
//                case "M": enemies.append(GoblinEnemy(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
//                case ">": enemies.append(GoblinEnemy(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "Z":
                    bossMusicStartX = CGFloat(col - 9)
                    enemies.append(BossEnemy(position: CGPoint(x: CGFloat(col), y: CGFloat(row))))
                case "|": level[row][col] = .ground
                default: print("Unknown mark: \(rows[row][col])")
                }
            }
        }
        return GameState(player: GamePlayer(
            position: position
        ), enemies: enemies, hasSword: hasSword, items: items, level: level, bossMusicStartX: bossMusicStartX)
    }
    
    func load(level: GameLevel) {
        self.level = level
        self.playerHealth = 100
        self.lastUpdate = nil
        self.spikeDamageCooldown = nil
        self.isGameOver = false
        self.isPaused = false
        self.isGameWon = false
        self.gameState = Self.gameState(for: level)
        self.soundEngine.music = .world1
        self.soundEngine.startLooping()
    }
    
    func update() {
        let now = Date()
        guard let lastUpdate else {
            self.lastUpdate = now
            return
        }
        let interval = now.timeIntervalSince(lastUpdate)
        self.lastUpdate = now
        
        guard !isGameOver else { return }
        guard !isPaused else { return }
        
        checkControllerInput()
        
        if let spikeDamageCooldown {
            if spikeDamageCooldown - interval > 0 {
                self.spikeDamageCooldown = spikeDamageCooldown - interval
            } else {
                self.spikeDamageCooldown = nil
            }
        }
        
        gameState.player.update(gameState, interval: interval)
        if let bossMusicStartX = gameState.bossMusicStartX,
           gameState.player.position.x >= bossMusicStartX,
           soundEngine.music != .boss1 {
            soundEngine.music = .boss1
            soundEngine.startLooping()
        }
        if gameState.player.animationStart == nil,
           gameState.isAttacking {
            gameState.isAttacking = false
        }
        for e in gameState.enemies.indices {
            gameState.enemies[e].update(gameState, interval: interval)
        }
        
        checkPlayerLevelCollisions()
        checkEnemyLevelCollisions()
        checkPlayerEnemyCollisions()
    }
    
    func gameOver() {
        isGameOver = true
        soundEngine.music = .gameover
        soundEngine.startPlaying()
    }
    
    func gameWon() {
        isGameWon = true
        soundEngine.music = .outro
        soundEngine.startLooping()
    }
    
    func checkControllerInput() {
        guard let gamepad else { return }
        
        if gamepad.leftThumbstick.xAxis.value < -0.05 || gamepad.leftThumbstick.xAxis.value > 0.05 {
            gameState.player.velocity.dx = CGFloat(gamepad.leftThumbstick.xAxis.value) * gamepadScale
        } else {
            gameState.player.velocity.dx = 0
        }
        
        if gamepad.buttonA.isPressed, gameState.player.velocity.dy == 0 {
            jump()
        }
        
        if gamepad.buttonB.isPressed, !gameState.isAttacking {
            attack()
        }
        
        if gamepad.buttonX.isPressed, !gameState.isAttacking {
            thrustAttack()
        }
        
        if gamepad.buttonY.isPressed, !gameState.isAttacking {
            block()
        } else if !gamepad.buttonY.isPressed {
            gameState.isBlocking = false
        }
    }
    
    func thrustAttack() {
        guard !gameState.isAttacking else { return }
        gameState.isAttacking = true
        playSound(.thrust)
        checkThrustAttack()
        gameState.player.startThrustAnimation()
    }
    
    func attack() {
        guard !gameState.isAttacking else { return }
        gameState.isAttacking = true
        playSound(.sword)
        checkAttack()
        gameState.player.startAttackAnimation()
    }
    
    func block() {
        // no blocking
        guard !gameState.isBlocking else { return }
        // no attacking
        guard !gameState.isAttacking else { return }
        // no jumping
        guard gameState.player.velocity.dy == 0 else { return }
        gameState.isBlocking = true
        gameState.player.frame = .heroBlocking
    }
    
    func checkAttack() {
        let attackBox = gameState.player.attackBox.offsetBy(dx: gameState.player.position.x,
                                                            dy: gameState.player.position.y)
        for (e, enemy) in gameState.enemies.enumerated() {
            if attackBox.intersects(enemy.boundingBox.offsetBy(dx: enemy.position.x,
                                                               dy: enemy.position.y)) {
                enemyDamage(e, gameState.player.attackStrength)
            }
        }
    }
    
    func checkThrustAttack() {
        var attackBox = gameState.player.attackBox.offsetBy(dx: gameState.player.position.x,
                                                            dy: gameState.player.position.y)
        attackBox.size.width += 1
        if gameState.player.direction == .left {
            attackBox.origin.x -= 1
        }
        for (e, enemy) in gameState.enemies.enumerated() {
            if attackBox.intersects(enemy.boundingBox.offsetBy(dx: enemy.position.x,
                                                               dy: enemy.position.y)) {
                enemyDamage(e, gameState.player.attackStrength * 2)
            }
        }
    }

    func playSound(_ effect: SoundEffect) {
        soundEngine.playSound(effect)
    }
        
    func jump() {
        gameState.player.velocity.dy = -7.7
        gameState.player.acceleration.dy = 0
    }
    
    func checkPlayerLevelCollisions() {
        checkLevelCollision(&gameState.player)
        checkItemCollision()
    }
    
    func checkEnemyLevelCollisions() {
        for e in gameState.enemies.indices {
            checkLevelCollision(&gameState.enemies[e])
        }
    }
    
    func checkPlayerEnemyCollisions() {
        let player = gameState.player
        var playerRange = player.boundingBox.offsetBy(dx: player.position.x,
                                                      dy: player.position.y)
        playerRange.origin.x -= playerRange.size.width / 2
        playerRange.size.width *= 2
        for (e, enemy) in gameState.enemies.enumerated() {
            if enemy.attackBox.offsetBy(dx: enemy.position.x,
                                        dy: enemy.position.y).intersects(playerRange) {
                enemyAttack(e)
            }
        }
    }
    
    func enemyAttack(_ e: Int) {
        guard (gameState.enemies[e].attackCooldown ?? 0) <= 0
        else { return }
        
        gameState.enemies[e].attackCooldown = 0.8
        checkEnemyAttack(from: e)
    }
    
    func checkEnemyAttack(from e: Int) {
        let attackBox = gameState.enemies[e].attackBox.offsetBy(dx: gameState.enemies[e].position.x,
                                                                dy: gameState.enemies[e].position.y)
        if attackBox.intersects(gameState.player.boundingBox.offsetBy(dx: gameState.player.position.x,
                                                                      dy: gameState.player.position.y)) {
            if gameState.isBlocking {
                damage(gameState.enemies[e].attackStrength / 3.0)
            } else {
                damage(gameState.enemies[e].attackStrength)
            }
        }
    }
    
    func enemyDamage(_ e: Int, _ amount: CGFloat) {
        gameState.enemies[e].health -= amount
        if gameState.enemies[e].health <= 0 {
            if gameState.enemies[e] is BossEnemy {
                gameState.hasKey = true
            }
            gameState.enemies.remove(at: e)
        }
    }
    
    func spikeDamage(_ amount: CGFloat) {
        guard (spikeDamageCooldown ?? 0) <= 0 else { return }
        damage(amount)
        spikeDamageCooldown = 1
    }

    func damage(_ amount: CGFloat) {
        playerHealth = max(0, playerHealth - amount)
    }
    
    func checkItemCollision() {
        let object = gameState.player
        let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
        var indicesToRemove = IndexSet()
        for i in gameState.items.indices {
            let item = gameState.items[i]
            if item.boundingBox.offsetBy(dx: item.position.x, dy: item.position.y).intersects(rect) {
                switch pickup(item) {
                case .keep:
                    break
                case .remove:
                    indicesToRemove.insert(i)
                }
            }
        }
        gameState.items.remove(atOffsets: indicesToRemove)
    }
    
    enum PickupResolution {
        case remove
        case keep
    }
    
    func nextLevel() {
        if let next = level.next {
            load(level: next)
        } else {
            gameWon()
        }
    }
    
    func pickup(_ item: LevelPieceContaining) -> PickupResolution {
        if let piece = (item as? LevelPieceContaining)?.piece {
            switch piece {
            case .entry:
                return .keep
            case .exitLocked:
                return .keep
            case .exitUnlocked:
                playSound(.teleport)
                nextLevel()
                return .keep
            case .key:
                playSound(.keyPickup)
                gameState.hasKey = true
                gameState.items = gameState.items.map { item in
                    if item.piece == .exitLocked {
                        return Goal(id: LevelPiece.exitUnlocked, piece: .exitUnlocked, position: item.position)
                    } else {
                        return item
                    }
                }
                return .remove
            case .sword:
                gameState.hasSword = true
                playSound(.swordPickup)
                return .remove
            }
        } else {
            return .keep
        }
    }
    
    func checkLevelCollision(_ object: inout GamePlayer) {
        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var groundCollision: CGPoint? = nil
            for x in (minX...maxX).reversed() {
                // check ground
                if maxY >= 0, maxY < gameState.level.count,
                   x >= 0, x < gameState.level[maxY].count {
                    switch gameState.level[maxY][x] {
                    case .ground:
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .spike:
                        spikeDamage(5)
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .ceilingSpike:
                        spikeDamage(5)
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .invisibleBlock:
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .fakeBlock:
                        break
                    case .empty:
                        break
                    case .goal:
                        break
                    }
                }
            }
            
            if let groundCollision {
                // stop any upward movement
                object.velocity.dy = 0
                // stop gravity
                object.acceleration = .zero
                // adjust position to fit the collision point
                object.position.y = groundCollision.y - object.boundingBox.maxY
            } else {
                // apply gravity
                object.acceleration.dy = 9.81
            }
        }

        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var ceilingCollision: CGPoint? = nil
            for x in minX...maxX {
                // check ceiling
                if minY >= 0, minY < gameState.level.count,
                   x >= 0, x < gameState.level[minY].count,
                   gameState.level[minY][x] == .ground {
                    ceilingCollision = CGPoint(x: x, y: minY)
                    break
                }
            }
            
            if let ceilingCollision {
                // stop any upward movement
                object.velocity.dy = 0
                // adjust position to fit the collision point
                object.position.y = ceil(object.position.y)
                // apply gravity
                object.acceleration.dy = 9.81
            }
        }
        
        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var wallCollision: CGPoint? = nil
            if object.velocity.dx < 0 {
                for y in minY...maxY {
                    // check walls
                    if y >= 0, y < gameState.level.count,
                       minX >= 0, minX < gameState.level[y].count,
                       gameState.level[y][minX] == .ground {
                        wallCollision = CGPoint(x: minX, y: y)
                        break
                    }
                }
                
                if let wallCollision {
                    // stop any horizontal movement
                    object.velocity.dx = 0
                    
                    // move to adjacent to the wall
                    object.position.x = ceil(object.position.x)
                }
            } else if object.velocity.dx > 0 {
                for y in minY...maxY {
                    // check walls
                    if y >= 0, y < gameState.level.count,
                       maxX >= 0, maxX < gameState.level[y].count,
                       gameState.level[y][maxX] == .ground {
                        wallCollision = CGPoint(x: minX, y: y)
                        break
                    }
                }
                
                if let wallCollision {
                    // stop any horizontal movement
                    object.velocity.dx = 0
                    
                    // move to adjacent to the wall
                    object.position.x = floor(object.position.x)
                }
            }
        }
    }
    
    func checkLevelCollision(_ object: inout AttackingGameObject) {
        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var groundCollision: CGPoint? = nil
            for x in (minX...maxX).reversed() {
                // check ground
                if maxY >= 0, maxY < gameState.level.count,
                   x >= 0, x < gameState.level[maxY].count {
                    switch gameState.level[maxY][x] {
                    case .ground:
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .spike:
                        spikeDamage(5)
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .ceilingSpike:
                        spikeDamage(5)
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .invisibleBlock:
                        groundCollision = CGPoint(x: x, y: maxY)
                    case .fakeBlock:
                        break
                    case .empty:
                        break
                    case .goal:
                        break
                    }
                }
            }
            
            if let groundCollision {
                // stop any upward movement
                object.velocity.dy = 0
                // stop gravity
                object.acceleration = .zero
                // adjust position to fit the collision point
                object.position.y = groundCollision.y - object.boundingBox.maxY
            } else {
                // apply gravity
                object.acceleration.dy = 9.81
            }
        }

        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var ceilingCollision: CGPoint? = nil
            for x in minX...maxX {
                // check ceiling
                if minY >= 0, minY < gameState.level.count,
                   x >= 0, x < gameState.level[minY].count,
                   gameState.level[minY][x] == .ground {
                    ceilingCollision = CGPoint(x: x, y: minY)
                    break
                }
            }
            
            if let ceilingCollision {
                // stop any upward movement
                object.velocity.dy = 0
                // adjust position to fit the collision point
                object.position.y = ceil(object.position.y)
                // apply gravity
                object.acceleration.dy = 9.81
            }
        }
        
        do {
            let rect = object.boundingBox.offsetBy(dx: object.position.x, dy: object.position.y)
            let minX = Int(floor(rect.minX))
            let maxX = Int(ceil(rect.maxX-1.0001))
            let minY = Int(floor(rect.minY))
            let maxY = Int(ceil(rect.maxY-1.0001))
            
            var wallCollision: CGPoint? = nil
            if object.velocity.dx < 0 {
                for y in minY...maxY {
                    // check walls
                    if y >= 0, y < gameState.level.count,
                       minX >= 0, minX < gameState.level[y].count,
                       gameState.level[y][minX] == .ground {
                        wallCollision = CGPoint(x: minX, y: y)
                        break
                    }
                }
                
                if let wallCollision {
                    // stop any horizontal movement
                    object.velocity.dx = 0
                    
                    // move to adjacent to the wall
                    object.position.x = ceil(object.position.x)
                }
            } else if object.velocity.dx > 0 {
                for y in minY...maxY {
                    // check walls
                    if y >= 0, y < gameState.level.count,
                       maxX >= 0, maxX < gameState.level[y].count,
                       gameState.level[y][maxX] == .ground {
                        wallCollision = CGPoint(x: minX, y: y)
                        break
                    }
                }
                
                if let wallCollision {
                    // stop any horizontal movement
                    object.velocity.dx = 0
                    
                    // move to adjacent to the wall
                    object.position.x = floor(object.position.x)
                }
            }
        }
    }
}
