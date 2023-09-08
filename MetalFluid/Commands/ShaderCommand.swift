//
//  ShaderCommand.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/07.
//

import Foundation
import MetalKit

protocol ShaderCommand {
    static var functionName: String { get }
}

enum ShaderCommandError: Error {
    case failedToCreateFunction
}

extension ShaderCommand {
    static func makePiplelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLComputePipelineState {
        guard let function = library.makeFunction(name: functionName) else {
            throw ShaderCommandError.failedToCreateFunction
        }
        return try device.makeComputePipelineState(function: function)
    }
}
