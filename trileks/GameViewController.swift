import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var scene : GameScene?
    @IBOutlet var skView : SKView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene(size: view.bounds.size)
        skView!.showsFPS = true
        skView!.showsNodeCount = true
        skView!.ignoresSiblingOrder = true
        scene!.scaleMode = .ResizeFill
        skView!.presentScene(scene)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func teleport(sender: UIButton!) {
        scene!.teleport()
    }
    
    @IBAction func restart(sender: UIButton!) {
        scene!.restart()
    }

}