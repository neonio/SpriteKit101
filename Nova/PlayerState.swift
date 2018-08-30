//
//  PlayerState.swift
//  Nova
//
//  Created by amoyio on 2018/8/30.
//  Copyright © 2018年 amoyio. All rights reserved.
//

import Foundation
import GameplayKit

fileprivate let characterAnimationKey = "Sprite Animation"

class PlayerState: GKState {
    weak var playerNode: SKNode?
    init(playerNode: SKNode){
        self.playerNode = playerNode
        super.init()
    }
}

class JumpingState: PlayerState {
    var isFinished: Bool = false
    let jumpForce: CGFloat = 75
    let textures: [SKTexture] = (0..<2).map({return "jump/\($0)"}).map(SKTexture.init)
    lazy var action = {SKAction.animate(with: textures, timePerFrame: 0.1)}()
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    override func didEnter(from previousState: GKState?) {
        playerNode?.removeAction(forKey: characterAnimationKey)
        playerNode?.run(action, withKey: characterAnimationKey)
        isFinished = false
        let jumpForceAction = SKAction.applyForce(CGVector(dx: 0, dy: jumpForce), duration: 0.1)
        playerNode?.run(jumpForceAction, completion: {[weak self] in
            guard let this = self else{ return }
            this.isFinished = true
        })
    }
}

class LandingState: PlayerState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is LandingState.Type, is JumpingState.Type:
            return false
        default:
            return true
        }
    }
    
    override func didEnter(from previousState: GKState?) {
        stateMachine?.enter(IdleState.self)
    }
}

class IdleState: PlayerState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is LandingState.Type, is IdleState.Type:
            return false
        default:
            return true
        }
    }
    let texture = SKTexture(imageNamed: "player/0")
    lazy var action = {
        SKAction.animate(with: [texture], timePerFrame: 0.1)
    }()
    override func didEnter(from previousState: GKState?) {
        playerNode?.removeAction(forKey: characterAnimationKey)
        playerNode?.run(action, withKey: characterAnimationKey)
    }
}

class WalkingState: PlayerState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is LandingState.Type, is WalkingState.Type :
            return false
        default:
            return true
        }
    }
    let textures: [SKTexture] = (0..<6).map({return "player/\($0)"}).map(SKTexture.init)
    lazy var action = {
        SKAction.animate(with: textures, timePerFrame: 0.1)
    }()
    
    override func didEnter(from previousState: GKState?) {
        playerNode?.removeAction(forKey: characterAnimationKey)
        playerNode?.run(action, withKey: characterAnimationKey)
    }
}

class StunnedState: PlayerState {
    
}



