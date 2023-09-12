//
//  CalForce.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/11.
//

import Foundation
import MetalKit
class CalForce : ShaderCommand{
    
    static let functionName: String = "calForce"
    private let pipelineState: MTLComputePipelineState
    private let T_amb: Float = 25.0
    init(device: MTLDevice, library: MTLLibrary) throws {
        self.pipelineState = try type(of: self).makePiplelineState(device: device, library: library)
    }
    func encode(in buffer: MTLCommandBuffer, outFTexture: MTLTexture, RTexture: MTLTexture,R_ambTexture: MTLTexture, TTexture: MTLTexture) {
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }
        var t_amb = T_amb
        let config = DispatchConfig(width: outFTexture.width, height: outFTexture.height)
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(outFTexture, index: 0)
        encoder.setTexture(RTexture, index: 1)
        encoder.setTexture(R_ambTexture, index: 2)
        encoder.setTexture(TTexture, index: 3)
        encoder.setBytes(&t_amb, length: MemoryLayout<Float>.size, index: 0)
        encoder.dispatchThreadgroups(config.threadgroupCount, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
}
