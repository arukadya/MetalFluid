import UIKit
import MetalKit

//let vertexData: [Float] = [-1, -1, 0, 1,
//                            1, -1, 0, 1,
//                           -1,  1, 0, 1,
//                            1,  1, 0, 1]

//let textureCoordinateData: [Float] = [0, 1,
//                                      1, 1,
//                                      0, 0,
//                                      1, 0]
//let startTime:Float = 0.0

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

