//
//  ViewController.swift
//  MetalShaderImageRender
//
//  Created by Shuichi Tsutsumi on 2017/09/10.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit

let vertexData: [Float] = [-1, -1, 0, 1,
                            1, -1, 0, 1,
                           -1,  1, 0, 1,
                            1,  1, 0, 1]

let textureCoordinateData: [Float] = [0, 1,
                                      1, 1,
                                      0, 0,
                                      1, 0]
let startTime:Float = 0.0

class ViewController: UIViewController, MTKViewDelegate {

    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var texture: MTLTexture!
    private var destTexture: MTLTexture!
    private var vertexBuffer: MTLBuffer!
    private var timeBuffer: MTLBuffer!
    private var texCoordBuffer: MTLBuffer!
    private var renderPipeline: MTLRenderPipelineState!
    private var computePipeline: MTLComputePipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    private let startDate = Date()
    @IBOutlet private weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Metalのセットアップ
        setupMetal()
        // 画像をテクスチャとしてロード
        loadTexture()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:MTLPixelFormat.rgba8Unorm , width: texture.width, height: texture.height, mipmapped: true)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead,MTLTextureUsage.shaderWrite]
         destTexture = device.makeTexture(descriptor: textureDescriptor)
        //
        makeBuffers()
        
        //
        makePipeline(pixelFormat: texture.pixelFormat)
        
        //
//        mtkView.enableSetNeedsDisplay = true
        // ビューの更新依頼 → draw(in:)が呼ばれる
//        mtkView.setNeedsDisplay()
    }

    private func setupMetal() {
        // MTLCommandQueueを初期化
        commandQueue = device.makeCommandQueue()
        mtkView.framebufferOnly = false
        // MTKViewのセットアップ
        mtkView.device = device
        mtkView.delegate = self
        
    }

    private func makeBuffers() {
        var size: Int
        size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size, options: [])
        
        size = textureCoordinateData.count * MemoryLayout<Float>.size
        texCoordBuffer = device.makeBuffer(bytes: textureCoordinateData, length: size, options: [])
        
        timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
        timeBuffer.label = "time"
    }
    
    private func makePipeline(pixelFormat: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
//        let function = library.makeFunction(name: "computeShader")!
        let function = library.makeFunction(name: "chaos")!
        computePipeline = try! device.makeComputePipelineState(function: function)
    }

    private func loadTexture() {
        // MTKTextureLoaderを初期化
        let textureLoader = MTKTextureLoader(device: device)
        // テクスチャをロード
        texture = try! textureLoader.newTexture(
            name: "highsierra",
            scaleFactor: view.contentScaleFactor,
            bundle: nil)
        // ピクセルフォーマットを合わせる
        mtkView.colorPixelFormat = texture.pixelFormat
    }
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        // ドローアブルを取得
        guard let drawable = view.currentDrawable else {return}
        guard let in_texture = texture else {return}

        var resolutionBuffer: MTLBuffer! = nil
        let screenSize = UIScreen.main.nativeBounds.size
        let resolutionData = [Float(screenSize.width), Float(screenSize.height)]
        let resolutionSize = resolutionData.count * MemoryLayout<Float>.size
        resolutionBuffer = device.makeBuffer(bytes: resolutionData, length: resolutionSize, options: [])
        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        guard let RcommandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        //
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        // エンコーダ生成
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else{
            return
        }
        let config = DispatchConfig(width: in_texture.width, height: in_texture.height)
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setTexture(in_texture, index: 0)
        computeEncoder.setTexture(destTexture, index: 1)
        computeEncoder.setBuffer(resolutionBuffer,offset: 0,index: 0)
        computeEncoder.setBuffer(timeBuffer,offset: 0,index: 1)
        computeEncoder.dispatchThreadgroups(config.threadgroupCount,threadsPerThreadgroup: config.threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        guard let renderEncoder = RcommandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        guard let renderPipeline = renderPipeline else {fatalError()}
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(destTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // エンコード完了
//        renderEncoder.endEncoding()
        
        renderEncoder.endEncoding()
        // 表示するドローアブルを登録
        RcommandBuffer.present(drawable)
        // コマンドバッファをコミット（エンキュー）
        RcommandBuffer.commit()
        let pTimeData = timeBuffer.contents()
        let vTimeData = pTimeData.bindMemory(to: Float.self, capacity: 1 / MemoryLayout<Float>.stride)
        vTimeData[0] = Float(Date().timeIntervalSince(startDate))
        
        // 完了まで待つ
        RcommandBuffer.waitUntilCompleted()
    }
}

