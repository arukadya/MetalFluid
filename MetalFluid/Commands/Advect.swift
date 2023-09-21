//
//  Advect.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/07.
//

import Foundation
import MetalKit

class AdvectVX : ShaderCommand{
    static let functionName: String = "advectVX"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVelocityX: MTLTexture, inVelocityY: MTLTexture,outVelocityX: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: inVelocityX.width, height: inVelocityX.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(inVelocityX, index: 0)
        encoder.setTexture(inVelocityY, index: 1)
        encoder.setTexture(outVelocityX, index: 2)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}

class AdvectVY : ShaderCommand{
    static let functionName: String = "advectVY"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVelocityX: MTLTexture, inVelocityY: MTLTexture,outVelocityY: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: inVelocityX.width, height: inVelocityX.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(inVelocityX, index: 0)
        encoder.setTexture(inVelocityY, index: 1)
        encoder.setTexture(outVelocityY, index: 2)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}

class AdvectCenter : ShaderCommand{
    static let functionName: String = "advect_Center"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVelocityX: MTLTexture, inVelocityY: MTLTexture,source: MTLTexture, target: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: source.width, height: target.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(inVelocityX, index: 0)
        encoder.setTexture(inVelocityY, index: 1)
        encoder.setTexture(source, index: 2)
        encoder.setTexture(target, index: 3)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}
