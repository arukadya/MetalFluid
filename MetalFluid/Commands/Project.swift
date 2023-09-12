//
//  Project.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/13.
//

import Foundation
import MetalKit

class DivergenceX : ShaderCommand{
    static let functionName: String = "divergenceX"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVelocityX: MTLTexture, Pressure: MTLTexture, Density: MTLTexture,Density_amb: MTLTexture,outVelocityX: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: outVelocityX.width, height: outVelocityX.height)
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(outVelocityX, index: 0)
        encoder.setTexture(Pressure, index: 1)
        encoder.setTexture(Density, index: 2)
        encoder.setTexture(Density_amb, index: 3)
        encoder.setTexture(outVelocityX, index: 4)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}

class DivergenceY : ShaderCommand{
    static let functionName: String = "divergenceY"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float;
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer, inVelocityY: MTLTexture, Pressure: MTLTexture, Density: MTLTexture,Density_amb: MTLTexture,outVelocityY: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        let config = DispatchConfig(width: outVelocityY.width, height: outVelocityY.height)
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(outVelocityY, index: 0)
        encoder.setTexture(Pressure, index: 1)
        encoder.setTexture(Density, index: 2)
        encoder.setTexture(Density_amb, index: 3)
        encoder.setTexture(outVelocityY, index: 4)
        encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}

class Project : ShaderCommand{
    static let functionName: String = "project"
    private let pipelineState: MTLComputePipelineState
    private var timeStep: Float;
    private static let MaxIterationCount = 10
    init(device: MTLDevice, library: MTLLibrary, timestep:Float) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
        self.timeStep = timestep;
    }
    func encode(in buffer: MTLCommandBuffer,SPressure: Slab,VelocityX: MTLTexture, VelocityY: MTLTexture,Density: MTLTexture,Density_amb: MTLTexture) {
        for _ in 0..<type(of: self).MaxIterationCount {
            guard let encoder = buffer.makeComputeCommandEncoder() else {
                return
            }
            let config = DispatchConfig(width: SPressure.source.width, height: SPressure.source.height)
            encoder.setComputePipelineState(pipelineState)
            encoder.setTexture(SPressure.source, index: 0)
            encoder.setTexture(VelocityX, index: 1)
            encoder.setTexture(VelocityY, index: 2)
            encoder.setTexture(Density, index: 3)
            encoder.setTexture(Density_amb, index: 4)
            encoder.setTexture(SPressure.dest, index: 5)
            encoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 0)
            encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
            encoder.endEncoding()
            SPressure.swap()
        }
    }
}
