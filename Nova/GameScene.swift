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
    private var previousTime: TimeInterval = 0
    private var playerIsFacingRight = true
    private var playerGameStateMachine: GKStateMachine?
    var stickEnabled: Bool = false
    var knobRadius: CGFloat = 50
    var playerSpeed:CGFloat = 4
    
    override func didMove(to view: SKView) {
        player = childNode(withName: "player")
        stick = childNode(withName: "stick")
        stickKnob = stick?.childNode(withName: "stickKnob")
        guard let player = player else {
            return
        }
        
        playerGameStateMachine = GKStateMachine(states: [
            JumpingState(playerNode: player),
            WalkingState(playerNode: player),
            IdleState(playerNode: player),
            LandingState(playerNode: player),
            StunnedState(playerNode: player)
            ])
        playerGameStateMachine?.enter(IdleState.self)
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
