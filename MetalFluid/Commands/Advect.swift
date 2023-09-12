//
//  Advect.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/07.
//

import Foundation
import MetalKit
class Advect : ShaderCommand{
    
    static let functionName: String = "chaos"
    private var resolutionBuffer: MTLBuffer!
    private let pipelineState: MTLComputePipelineState
    private let timestep: Float = 0.1
    private var time: Float
    private let dissipation: Float = 0.99
    
    init(device: MTLDevice, library: MTLLibrary) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        let screenSize = UIScreen.main.nativeBounds.size
        let resolutionData = [Float(screenSize.width), Float(screenSize.height)]
        let resolutionSize = resolutionData.count * MemoryLayout<Float>.size
        resolutionBuffer = device.makeBuffer(bytes: resolutionData, length: resolutionSize, options: [])
        time = 0.0
    }
//    func encode(in buffer: MTLCommandBuffer, source: MTLTexture, velocity: MTLTexture, dest: MTLTexture, dissipation: Float) {
    func encode(in buffer: MTLCommandBuffer, source: MTLTexture, dest: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        
        var timestep = self.timestep
        var time = self.time
        //var dissipation = self.dissipation
        
        let config = DispatchConfig(width: source.width, height: source.height)
        encoder.setComputePipelineState(pipelineState)
//        encoder.setBytes(&dissipation, length: MemoryLayout<Float>.size, index: 1)
//        encoder.setTexture(source, index: 0)
//        encoder.setTexture(velocity, index: 1)
//        encoder.setTexture(dest, index: 2)
        
        
        encoder.setTexture(source, index: 0)
        encoder.setTexture(dest, index: 1)
        encoder.setBuffer(resolutionBuffer,offset: 0,index: 0)
        encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 1)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
//        encoder.setBuffer(timestep,offset: 0,index: 1)
        encoder.endEncoding()
        self.time += timestep
    }
}

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
