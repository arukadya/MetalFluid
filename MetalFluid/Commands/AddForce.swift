import Foundation
import MetalKit

class AddForceX : ShaderCommand{
    static let functionName: String = "addForce_X"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float = 0.125
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVTexture: MTLTexture, outVTexture: MTLTexture,FTexture: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: inVTexture.width, height: inVTexture.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(inVTexture, index: 0)
        encoder.setTexture(outVTexture, index: 1)
        encoder.setTexture(FTexture, index: 2)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}

class AddForceY : ShaderCommand{
    static let functionName: String = "addForce_Y"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVTexture: MTLTexture, outVTexture: MTLTexture,FTexture: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: inVTexture.width, height: inVTexture.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(inVTexture, index: 0)
        encoder.setTexture(outVTexture, index: 1)
        encoder.setTexture(FTexture, index: 2)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}
