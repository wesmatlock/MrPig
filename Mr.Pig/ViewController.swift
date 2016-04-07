//
//  AppDelegate.swift
//  MrPig
//
//  Created by Wesley Matlock on 4/5/16.
//  Copyright (c) 2016 insoc.net. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit

class ViewController: UIViewController {
    
    let game = GameHelper.sharedInstance
    
    var scnView: SCNView!
    var gameScene: SCNScene!
    var splashScene: SCNScene!
    
    var pigNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var lightFollowNode: SCNNode!
    var trafficNode: SCNNode!

    var collisionNode: SCNNode!
    var frontCollisionNode: SCNNode!
    var backCollisionNode: SCNNode!
    var leftCollisionNode: SCNNode!
    var rightCollisionNode: SCNNode!
    
    var driveLeftAction: SCNAction!
    var driveRightAction: SCNAction!
    
    var jumpLeftAction: SCNAction!
    var jumpRightAction: SCNAction!
    var jumpForwardAction: SCNAction!
    var jumpBackwardAction: SCNAction!
    
    var triggerGameOver: SCNAction!
    
    let BitMaskPig = 1
    let BitMaskVehicle = 2
    let BitMaskObstacle = 4
    let BitMaskFront = 8
    let BitMaskBack = 16
    let BitMaskLeft = 32
    let BitMaskRight = 64
    let BitMaskCoin = 128
    let BitMaskHouse = 256
    
    var activeCollisionsBitMask: Int = 0

    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScenes()
        setupNodes()
        setupActions()
        setupTraffic()
        setupGestures()
        setupSounds()
        
        game.state = .TapToPlay
    }
    
    func setupScenes() {
        
        scnView = SCNView(frame: view.frame)
        view.addSubview(scnView)
        
        gameScene = SCNScene(named: "/MrPig.scnassets/GameScene.scn")
        splashScene = SCNScene(named: "/MrPig.scnassets/SplashScene.scn")
        
        scnView.scene = splashScene
        scnView.delegate = self
        gameScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        
        pigNode = gameScene.rootNode.childNodeWithName("MrPig", recursively: true)
        
        cameraNode = gameScene.rootNode.childNodeWithName("camera", recursively: true)
        cameraNode.addChildNode(game.hudNode)
        
        cameraFollowNode = gameScene.rootNode.childNodeWithName("FollowCamera", recursively: true)
        lightFollowNode = gameScene.rootNode.childNodeWithName("FollowLight", recursively: true)
        trafficNode = gameScene.rootNode.childNodeWithName("Traffic", recursively: true)
        
        collisionNode = gameScene.rootNode.childNodeWithName("Collisions", recursively: true)
        frontCollisionNode = gameScene.rootNode.childNodeWithName("Front", recursively: true)
        backCollisionNode = gameScene.rootNode.childNodeWithName("Back", recursively: true)
        leftCollisionNode = gameScene.rootNode.childNodeWithName("Left", recursively: true)
        rightCollisionNode = gameScene.rootNode.childNodeWithName("Right", recursively: true)
        
        pigNode.physicsBody?.contactTestBitMask = BitMaskVehicle | BitMaskCoin | BitMaskHouse
        
        frontCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        backCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        leftCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        rightCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        
    }
    
    func setupActions() {
     
        driveLeftAction = SCNAction.repeatActionForever(SCNAction.moveBy(SCNVector3Make(-2.0, 0, 0), duration: 1.0))
        driveRightAction = SCNAction.repeatActionForever(SCNAction.moveBy(SCNVector3Make(2.0, 0, 0), duration: 1.0))
        
        let duration = 0.2
        
        let bounceUpAction = SCNAction.moveByX(0, y: 1.0, z: 0, duration: duration * 0.5)
        let bounceDownAction = SCNAction.moveByX(0, y: -1.0, z: 0, duration: duration * 0.5)
        
        bounceUpAction.timingMode = .EaseOut
        bounceDownAction.timingMode = .EaseIn
        
        let bounceAction = SCNAction.sequence([bounceUpAction, bounceDownAction])
        
        let moveLeftAction = SCNAction.moveByX(-1, y: 0, z: 0, duration: duration)
        let moveRightAction = SCNAction.moveByX(1, y: 0, z: 0, duration: duration)
        let moveForwardAction = SCNAction.moveByX(0, y: 0, z: -1.0, duration: duration)
        let moveBackwardAction = SCNAction.moveByX(0, y: 0, z: 1.0, duration: duration)
        
        let turnLeftAction = SCNAction.rotateToX(0, y: convertToRadians(-90), z: 0, duration: duration, shortestUnitArc: true)
        let turnRightAction = SCNAction.rotateToX(0, y: convertToRadians(90), z: 0, duration: duration, shortestUnitArc: true)
        let turnForwardAction = SCNAction.rotateToX(0, y: convertToRadians(180), z: 0, duration: duration, shortestUnitArc: true)
        let turnBackwardAction = SCNAction.rotateToX(0, y: convertToRadians(0), z: 0, duration: duration, shortestUnitArc: true)
        
        jumpLeftAction = SCNAction.group([turnLeftAction, bounceAction, moveLeftAction])
        jumpRightAction = SCNAction.group([turnRightAction, bounceAction, moveRightAction])
        jumpForwardAction = SCNAction.group([turnForwardAction, bounceAction, moveForwardAction])
        jumpBackwardAction = SCNAction.group([turnBackwardAction, bounceAction, moveBackwardAction])
        
        let spinAround = SCNAction.rotateByX(0, y: convertToRadians(720), z: 0, duration: 2.0)
        let riseUp = SCNAction.moveByX(0, y: 10, z: 0, duration: 2.0)
        let fadeOut = SCNAction.fadeOpacityTo(0, duration: 2.0)
        let goodByePig = SCNAction.group([spinAround, riseUp, fadeOut])
        
        let gameOver = SCNAction.runBlock { (node) in
            
            self.pigNode.position = SCNVector3Zero
            self.pigNode.opacity = 1.0
            self.startSplash()
        }
        
        triggerGameOver = SCNAction.sequence([goodByePig, gameOver])
    }
    
    func setupTraffic() {
        
        for node in trafficNode.childNodes {
            
            if node.name?.containsString("Bus") == true {
                
                driveLeftAction.speed = 1.0
                driveRightAction.speed = 1.0
            }
            else {

                driveLeftAction.speed = 2.0
                driveRightAction.speed = 2.0
            }
            
            if node.eulerAngles.y < 0 {
                
                node.runAction(driveLeftAction)
            }
            else {
                
                node.runAction(driveRightAction)
            }
        }
    }
    
    func setupGestures() {
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: .handleGesture)
        swipeRight.direction = .Right
        scnView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: .handleGesture)
        swipeLeft.direction = .Left
        scnView.addGestureRecognizer(swipeLeft)
        
        let swipeForward = UISwipeGestureRecognizer(target: self, action: .handleGesture)
        swipeForward.direction = .Up
        scnView.addGestureRecognizer(swipeForward)
        
        let swipeBackward = UISwipeGestureRecognizer(target: self, action: .handleGesture)
        swipeBackward.direction = .Down
        scnView.addGestureRecognizer(swipeBackward)
    }
    
    func setupSounds() {
        
        if game.state == .TapToPlay {
            
            let music = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Music.mp3")
            
            music?.volume = 0.3
            music?.loops = true
            music?.shouldStream = true
            music?.positional = false
            
            let musicPlayer = SCNAudioPlayer(source: music!)
            splashScene.rootNode.addAudioPlayer(musicPlayer)
        }
        else if game.state == .Playing {
            
            let traffic = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Traffic.mp3")
            
            traffic?.volume = 0.3
            traffic?.loops = true
            traffic?.shouldStream = true
            traffic?.positional = true
            
            let trafficPlayer = SCNAudioPlayer(source: traffic!)
            gameScene.rootNode.addAudioPlayer(trafficPlayer)
            
            game.loadSound("Jump", fileNamed: "MrPig.scnassets/Audio/Jump.wav")
            game.loadSound("Blocked", fileNamed: "MrPig.scnassets/Audio/Blocked.wav")
            game.loadSound("Crash", fileNamed: "MrPig.scnassets/Audio/Crash.wav")
            game.loadSound("CollectCoin", fileNamed: "MrPig.scnassets/Audio/CollectCoin.wav")
            game.loadSound("BankCoin", fileNamed: "MrPig.scnassets/Audio/BankCoin.wav")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    //MARK: - Movement Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if game.state == .TapToPlay {
            startGame()
        }
    }
    
    func handleGesture(sender: UISwipeGestureRecognizer) {

        guard game.state == .Playing else { return }

        let activeFrontCollision = activeCollisionsBitMask & BitMaskFront == BitMaskFront
        let activeBackCollision = activeCollisionsBitMask & BitMaskBack == BitMaskBack
        let activeLeftCollision = activeCollisionsBitMask & BitMaskLeft == BitMaskLeft
        let activeRightCollision = activeCollisionsBitMask & BitMaskRight == BitMaskRight
        
        guard (sender.direction == .Up && !activeFrontCollision)  ||
            (sender.direction == .Down && !activeBackCollision) ||
            (sender.direction == .Left && !activeLeftCollision) ||
            (sender.direction == .Right && !activeRightCollision)  else {
        
                game.playSound(pigNode, name: "Blocked")
                return
        }

        switch sender.direction {
            
        case UISwipeGestureRecognizerDirection.Up:
            pigNode.runAction(jumpForwardAction)
            
        case UISwipeGestureRecognizerDirection.Down:
            pigNode.runAction(jumpBackwardAction)
            
        case UISwipeGestureRecognizerDirection.Left:
            
            if pigNode.position.x > -15 {
                pigNode.runAction(jumpLeftAction)
            }
            
        case UISwipeGestureRecognizerDirection.Right:
            
            if pigNode.position.x < 15 {
                pigNode.runAction(jumpRightAction)
            }
        default:
            break
        }
        
        game.playSound(pigNode, name: "Jump")
    }
    
    func updatePositions() {
        
        collisionNode.position = pigNode.presentationNode.position
        
        let lerpX = (pigNode.position.x - cameraFollowNode.position.x) * 0.05
        let lerpZ = (pigNode.position.z - cameraFollowNode.position.z) * 0.05
        
        cameraFollowNode.position.x += lerpX
        cameraFollowNode.position.z += lerpZ
        lightFollowNode.position = cameraFollowNode.position
    }
    
    func updateTraffic() {
        
        for node in trafficNode.childNodes {
            
            if node.position.x > 25 {
                node.position.x = -25
            }
            else if node.position.x < -25 {
                node.position.x = 25
            }
        }
    }
    
    //MARK: - Gmae Methods
    func startGame() {
        
        splashScene.paused = true
        
        let transition = SKTransition.doorsOpenVerticalWithDuration(1.0)
        
        scnView.presentScene(gameScene, withTransition: transition, incomingPointOfView: nil) { 
            
            self.game.state = .Playing
            self.setupSounds()
            self.gameScene.paused = false
        }
    }
    
    func stopGame() {
    
        game.state = .GameOver
        game.reset()
        pigNode.runAction(triggerGameOver)
    }
    
    func startSplash() {
    
        gameScene.paused = true

        let transition = SKTransition.doorsOpenVerticalWithDuration(1.0)
        
        scnView.presentScene(splashScene, withTransition: transition, incomingPointOfView: nil) { 
            
            self.game.state = .TapToPlay
            self.setupSounds()
            self.splashScene.paused = false
        }
    }
}

//MARK: - SCNSceneRendererDelegate
extension ViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        guard game.state == .Playing else { return }
        
        game.updateHUD()
        updatePositions()
        updateTraffic()
    }
}

//MARK: - SCNPhysicsContactDelegate
extension ViewController: SCNPhysicsContactDelegate {
 
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        
        guard game.state == .Playing else { return }
        
        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        }
        else {
            collisionBoxNode = contact.nodeA
        }
        
        activeCollisionsBitMask |= collisionBoxNode.physicsBody!.categoryBitMask
        
        var contactNode: SCNNode!
        
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskPig {
            contactNode = contact.nodeB
        }
        else {
            contactNode = contact.nodeA
        }
        
        if contactNode.physicsBody?.categoryBitMask == BitMaskVehicle {
            game.playSound(pigNode, name: "Crash")
            stopGame()
        }
        
        if contactNode.physicsBody?.categoryBitMask == BitMaskCoin {
            
            contactNode.hidden = true
            contactNode.runAction(SCNAction.waitForDurationThenRunBlock(10, block: { (node) in
                node.hidden = false
            }))
            game.playSound(pigNode, name: "CollectCoin")
            game.collectCoin()
        }

        if contactNode.physicsBody?.categoryBitMask == BitMaskHouse {

            if game.bankCoins() == true {
                game.playSound(pigNode, name: "BankCoin")
            }
        }
    }
    
    func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        
        guard game.state == .Playing else { return }

        var collisionBoxNode: SCNNode!
        
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        }
        else {
            collisionBoxNode = contact.nodeA
        }
        
        activeCollisionsBitMask &= ~collisionBoxNode.physicsBody!.categoryBitMask
    }
}

//MARK: - Selector
private extension Selector {
    
    static let handleGesture = #selector(ViewController.handleGesture(_:))
}
