import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
//
//func - (left: CGPoint, right: CGPoint) -> CGPoint {
//    return CGPoint(x: left.x - right.x, y: left.y - right.y)
//}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
    func cardinalized() -> CGPoint {
        return CGPoint(x: round(self.x), y: round(self.y))
    }
}

struct PhysicsCategory {
    static let None     : UInt32 = 0
    static let All      : UInt32 = UInt32.max
    static let Robot    : UInt32 = 0b1
    static let Wreck    : UInt32 = 0b10
    static let Player   : UInt32 = 0b100
}

class Actor {
    var alive = true
    var position : CGPoint
    init(position : CGPoint) {
        self.position = position
    }
}

class Player : Actor {
    let node = SKSpriteNode(imageNamed: "frog")
    override init(position : CGPoint) {
        super.init(position: position)
        self.node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 50, height: 50))
        node.physicsBody?.dynamic = true
        node.physicsBody?.categoryBitMask = PhysicsCategory.Player
        node.physicsBody?.contactTestBitMask = PhysicsCategory.Robot + PhysicsCategory.Wreck
        node.physicsBody?.collisionBitMask = PhysicsCategory.None
    }
    func move(position: CGPoint) {
        self.position = position
        let actionMove = SKAction.moveTo(self.position, duration: 0.75)
        self.node.runAction(actionMove)
    }
    func teleport(position: CGPoint) {
        self.position = position
        self.node.position = position
    }
}

func ==(lhs: Robot, rhs: Robot) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

class Robot : Actor, Equatable, Hashable {
    let node = SKSpriteNode(imageNamed: "robot")
    let wreck = SKSpriteNode(imageNamed: "frog")
    override init(position: CGPoint) {
        super.init(position: position)
        self.node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 50, height: 50))
        node.physicsBody?.dynamic = true
        node.physicsBody?.categoryBitMask = PhysicsCategory.Robot
        node.physicsBody?.contactTestBitMask = PhysicsCategory.Robot + PhysicsCategory.Wreck
        node.physicsBody?.collisionBitMask = PhysicsCategory.None
    }
    func move(position: CGPoint) {
        self.position = position
        let actionMove = SKAction.moveTo(self.position, duration: 1.0)
        self.node.runAction(actionMove)
    }
    
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player : Player = Player(position: CGPoint(x: 0, y: 0))
    var robots : [Robot] = []

    
    override func didMoveToView(view: SKView) {
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        self.restart()
    }
    
    func randomGridPosition() -> CGPoint {
        let gridX = UInt32(round(size.width / 82))
        let gridY = UInt32(round(size.height / 82))
        let actualX = arc4random_uniform(gridX) * 82
        let actualY = arc4random_uniform(gridY) * 82
        return CGPoint(x: CGFloat(actualX), y: CGFloat(actualY))
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        var animatingRobots = false
        for robot in robots {
            if robot.node.hasActions() {
                animatingRobots = true
                break
            }
        }

        if !animatingRobots && !player.node.hasActions(){
            let touch = touches.first as! UITouch
            let touchLocation = touch.locationInNode(self)
            let offset = touchLocation + player.position
            let direction = offset.normalized().cardinalized()
            let moveAmount = direction * 82
            let realDest = moveAmount + player.position
            player.move(realDest)

            for robot in robots {
                let offset = realDest + robot.position
                let direction = offset.normalized().cardinalized()
                let moveAmount = direction * 82
                let realDest = moveAmount + robot.position
                robot.move(realDest)
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if((contact.bodyA.categoryBitMask+contact.bodyB.categoryBitMask) & PhysicsCategory.Player != 0) {
            playerDies()
        } else {
            robotsDie(contact.bodyA.node!, otherNode: contact.bodyB.node!)
        }
    }
    
    func playerDies() {
        let blinkOut = SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.fadeInWithDuration(0.3),
            SKAction.fadeOutWithDuration(0.3),
            SKAction.fadeInWithDuration(0.3),
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()])
        player.node.runAction(blinkOut)
    }
    
    func robotsDie(robotNode1: SKNode, otherNode robotNode2: SKNode) {
        let removeAfterDelay = SKAction.sequence([SKAction.fadeOutWithDuration(0.3), SKAction.removeFromParent()])
        robotNode1.runAction(removeAfterDelay)
        robotNode2.runAction(removeAfterDelay)
        var collidingRobots : [Robot] = [] as [Robot]
        let wreck = SKSpriteNode(imageNamed: "wreck")
        for (index,robot) in enumerate(robots) {
            if (robot.node == robotNode1 || robot.node == robotNode2) {
                collidingRobots.append(robot)
            }
        }
        var newRobots : [Robot] = []
        var robotSet : Set<Robot>  = Set(robots).subtract(collidingRobots)
        for robot in robotSet {
            newRobots.append(robot)
        }
        robots = newRobots
        
        wreck.position = collidingRobots.first!.position
        wreck.alpha = 0.0
        self.addChild(wreck)
        wreck.runAction(SKAction.fadeInWithDuration(0.3))
    }
    
    func teleport() {
        player.teleport(randomGridPosition())
    }
    
    func restart() {
        self.player = Player(position: randomGridPosition())
        backgroundColor = SKColor.whiteColor()
        addChild(player.node)
        
        for _ in 1...2 {
            let robot = Robot(position: randomGridPosition())
            robots.append(robot)
            addChild(robot.node)
        }
    }
}