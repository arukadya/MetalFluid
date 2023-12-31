//
//  Slab.swift
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/07.
//

import Foundation
import MetalKit

final class Slab {
    var source: MTLTexture
    var dest: MTLTexture
    
    init(source: MTLTexture, dest: MTLTexture) {
        self.source = source
        self.dest = dest
    }
    
    func swap() {
        let temp = source
        source = dest
        dest = temp
    }
}

extension MTLDevice{
    func makeSurface(width: Int, height: Int, format: SurfaceFloatFormat, numberOfComponents: Int) -> MTLTexture? {
        let pixelFormat: MTLPixelFormat
        switch (format, numberOfComponents) {
        case (.half, 1):
            pixelFormat = .r16Float
        case (.half, 2):
            pixelFormat = .rg16Float
        case (.half, 3), (.half, 4):
            pixelFormat = .rgba16Float
        case (.float, 1):
            pixelFormat = .r32Float
        case (.float, 2):
            pixelFormat = .rg32Float
        case (.float, 3), (.float, 4):
            pixelFormat = .rgba32Float
        default:
            pixelFormat = .r16Float
        }
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        return makeTexture(descriptor: desc)
    }
    
    func makeSlab(width: Int, height: Int, format: SurfaceFloatFormat, numberOfComponents: Int) -> Slab? {
        guard let source = makeSurface(width: width, height: height, format: format, numberOfComponents: numberOfComponents),
            let dest = makeSurface(width: width, height: height, format: format, numberOfComponents: numberOfComponents) else {
                return nil
        }
        return Slab(source: source, dest: dest)
    }
}
