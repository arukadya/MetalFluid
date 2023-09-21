import UIKit
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {

    private let device = MTLCreateSystemDefaultDevice()!
    var renderer: Renderer?
    @IBOutlet private weak var mtkView: MTKView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Metalのセットアップ
        setupMetal()
        mtkView.colorPixelFormat = MTLPixelFormat.rgba8Unorm
        renderer = Renderer(with: mtkView)
    }

    private func setupMetal() {
        // MTLCommandQueueを初期化
        //commandQueue = device.makeCommandQueue()
        mtkView.framebufferOnly = false
        // MTKViewのセットアップ
        mtkView.device = device
        mtkView.delegate = self
    }
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
    }
}

