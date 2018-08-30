//
//  GameScene.swift
//  Nova
//
//  Created by amoyio on 2018/8/29.
//  Copyright © 2018年 amoyio. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var player: SKNode?
    private var stick: SKNode?
    private var stickKnob: SKNode?
    private var moonNode: SKNode?
    private var mountain1Node: SKNode?
    private var mountain2Node: SKNode?
    private var previousTime: TimeInterval = 0
    private var playerIsFacingRight = true
    private var playerGameStateMachine: GKStateMachine?
    private var mainCamera:SKCameraNode?
    var stickEnabled: Bool = false
    var knobRadius: CGFloat = 50
    var playerSpeed:CGFloat = 4
    
    override func didMove(to view: SKView) {
        player = childNode(withName: "player")
        stick = childNode(withName: "stick")
        stickKnob = stick?.childNode(withName: "stickKnob")
        moonNode = childNode(withName: "moon")
        mountain1Node = childNode(withName: "mountain_1")
        mountain2Node = childNode(withName: "mountain_2")
        mainCamera = childNode(withName: "CameraNode") as? SKCameraNode
        
        guard let player = player else {
            return
        }
        physicsWorld.contactDelegate = self
        playerGameStateMachine = GKStateMachine(states: [
            JumpingState(playerNode: player),
            WalkingState(playerNode: player),
            IdleState(playerNode: player),
            LandingState(playerNode: player),
            StunnedState(playerNode: player)
            ])
        playerGameStateMachine?.enter(IdleState.self)
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {(timer) in
            self.spawnMeteor()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let stick = stick , let stickKnob = stickKnob else { return }
        for touch in touches {
            let touchLocation = touch.location(in: stick)
            stickEnabled = stickKnob.frame.contains(touchLocation)
            let screenLocation = touch.location(in: self)
            if !stick.contains(screenLocation) {
                playerGameStateMachine?.enter(JumpingState.self)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let stick = stick , let stickKnob = stickKnob else { return }
        guard stickEnabled else {return}
        for touch in touches {
            let position = touch.location(in: stick)
            let distance = sqrt(pow(position.x, 2)+pow(position.y,2))
            //atan2(y, x) 等价于 atan(y/x)，但 atan2 的最大优势是可以正确处理 x=0 而 y≠0 的情况，而不必进行会引发除零异常的 y/x 操作。
            let angle = atan2(position.y, position.x)
            if knobRadius > distance {
                stickKnob.position = position
            }else{
                stickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let stick = stick , let stickKnob = stickKnob else { return }
        for touch in touches {
            let xCoord = touch.location(in: stick).x
            let xLimit:CGFloat = 200
            if xCoord > -xLimit && xCoord < xLimit {
                resetPostion()
            }
        }
    }
    
    func resetPostion() {
        let moveReset = SKAction.move(to: .zero, duration: 0.1)
        moveReset.timingMode = .linear
        stickKnob?.run(moveReset)
        stickEnabled = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPostion()
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        var deltaTime:Double = 0
        if previousTime != 0 {
            deltaTime = currentTime - previousTime
        }
        mainCamera?.position.x = player?.position.x ?? 0
        stick?.position.x = (mainCamera?.position.x ?? 0) - 280
        stick?.position.y = (mainCamera?.position.y ?? 0) - 100
        
        let mountainOffsetX1Action = SKAction.moveTo(x: (player?.position.x ?? 0) / -10, duration: 0)
        let mountainOffsetX2Action = SKAction.moveTo(x: (player?.position.x ?? 0) / -20, duration: 0)
        mountain1Node?.run(mountainOffsetX1Action)
        mountain2Node?.run(mountainOffsetX2Action)
        
        let moonOffsetXAction = SKAction.moveTo(x: (player?.position.x ?? 0) / -5 , duration: 0)
        moonNode?.run(moonOffsetXAction)
        
        previousTime = currentTime
        guard let knob = stickKnob else {return}
        let xPos = knob.position.x
        let positivePos = xPos < 0 ? -xPos : xPos
        if floor(positivePos) != 0 {
            playerGameStateMachine?.enter(WalkingState.self)
        }else{
            playerGameStateMachine?.enter(IdleState.self)
        }
        let forward = CGVector(dx: CGFloat(deltaTime) * xPos * playerSpeed, dy: 0)
        let move = SKAction.move(by: forward, duration: 0)
        var face:SKAction
        var moveAction:SKAction!
        if xPos < 0 && playerIsFacingRight {
            face = SKAction.scaleX(to: -1, duration: 0)
            moveAction = SKAction.sequence([move,face])
            playerIsFacingRight = false
        }else if xPos > 0 && !playerIsFacingRight{
            face = SKAction.scaleX(to: 1, duration: 0)
            moveAction = SKAction.sequence([move,face])
            playerIsFacingRight = true
        }else{
            moveAction = move
        }
        player?.run(moveAction)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    struct Collision {
        enum Masks: Int {
            case killing, player, reward, ground
            var bitmask: UInt32 {return 1<<self.rawValue}
        }
        let masks : (first : UInt32, second : UInt32)
        
        func matches (_ first : Masks, _ second : Masks) -> Bool {
            return (first.bitmask == masks.first && second.bitmask == masks.second) ||
                (first.bitmask == masks.second && second.bitmask == masks.first)
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = Collision(masks: (first: contact.bodyA.categoryBitMask, second: contact.bodyB.categoryBitMask))
        if collision.matches(.killing, .killing) {
            if contact.bodyA.node?.name == "Meteor", let meteor = contact.bodyA.node {
                meteor.removeFromParent()
            }
        }
        
        if collision.matches(.player, .killing) {
            let dieAction = SKAction.move(to: CGPoint(x: -300, y: -100), duration: 0)
            player?.run(dieAction)
        }
        
        if collision.matches(.ground, .killing) {
            if contact.bodyA.node?.name == "Meteor", let meteor = contact.bodyA.node {
                createMolten(at: meteor.position)
                meteor.removeFromParent()
            }
            
            if contact.bodyB.node?.name == "Meteor", let meteor = contact.bodyB.node {
                createMolten(at: meteor.position)
                meteor.removeFromParent()
            }
        }
        
        if collision.matches(.player, .ground) {
            playerGameStateMachine?.enter(LandingState.self)
        }
    }
}

extension GameScene {
    func spawnMeteor() {
        let node = SKSpriteNode(imageNamed: "meteor")
        node.name = "Meteor"
        let randomXPosition = Int(arc4random_uniform(UInt32(self.size.width)))
        node.position = CGPoint(x: randomXPosition, y: 270)
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        node.zPosition = 5
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 30)
        node.physicsBody = physicsBody
        
        physicsBody.categoryBitMask = Collision.Masks.killing.bitmask
        physicsBody.collisionBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.contactTestBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.fieldBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        
        physicsBody.affectedByGravity = true
        physicsBody.allowsRotation = false
        physicsBody.restitution = 0.2
        physicsBody.friction = 10
        
        addChild(node)
    }
    
    func createMolten(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "molten")
        node.position.x = position.x
        node.position.y = position.y - 110
        node.zPosition = 4
        
        addChild(node)
        
        let action = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent(),
            ])
        
        node.run(action)
    }
}
