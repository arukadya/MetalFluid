import Foundation
import MetalKit
import Accelerate

enum SurfaceFloatFormat {
    case float, half
}

struct Fluid {
    static let floatFormat: SurfaceFloatFormat = .half
    static let densityComponents: Int = 4
    static let range: Int = 100;
    let width: Int
    let height: Int
    //let range: Int
    let velocity: Slab
    let pressure: Slab
    let density: Slab
    let InTESTure: MTLTexture!
    let OutTESTure: MTLTexture!
    //let divergence: MTLTexture
    
    init?(device: MTLDevice, width: Int, height: Int) {
        let format = Fluid.floatFormat
        let screenSize = UIScreen.main.nativeBounds.size
        let resolutionData = [Float(screenSize.width), Float(screenSize.height)]
        let resolutionSize = resolutionData.count * MemoryLayout<Float>.size
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:MTLPixelFormat.rgba8Unorm , width: width, height: height, mipmapped: true)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead,MTLTextureUsage.shaderWrite]
        InTESTure = device.makeTexture(descriptor: textureDescriptor)
        OutTESTure = device.makeTexture(descriptor: textureDescriptor)
        
        guard let velocity = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 2),
        let pressure = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 1),
         let density = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 1)
        else{
            return nil
        }
        self.velocity = velocity
        self.pressure = pressure
        self.density = density
        //mtkView.colorPixelFormat = texture.pixelFormat
        
        self.width = width
        self.height = height
        //self.range = range
        createVelocityInitialState()
        createPressureInitialState()
        createDensityInitialState()
    }
    
    private func createVelocityInitialState() {
        var initialGrid: [Float] = Array(repeating: 0, count: width * height * 2)
//        for i in 0..<height {
//            for j in 0..<width {
//                let radianX = 2 * Float.pi * Float(j % 100) / 100
//                let radianY = 2 * Float.pi * Float(i % 100) / 100
//                initialGrid[j*2 + i*width*2] = sin(radianX)
//                initialGrid[j*2 + i*width*2 + 1] = cos(radianY)
//            }
//        }
        switch type(of: self).floatFormat {
        case .float:
            let region = MTLRegionMake2D(0, 0, width, height)
            let rowBytes = MemoryLayout<Float>.size * width * 2
            velocity.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid,
                                    bytesPerRow: rowBytes)
        case .half:
            var outputGrid: [UInt16] = Array(repeating: 0, count: width * height * 2)
            let sourceRowBytes = MemoryLayout<Float>.size * width * 2
            let destRowBytes = MemoryLayout<UInt16>.size * width * 2
            var source = vImage_Buffer(data: &initialGrid, height: UInt(height), width: UInt(width) * 2, rowBytes: sourceRowBytes)
            var dest = vImage_Buffer(data: &outputGrid, height: UInt(height), width: UInt(width) * 2, rowBytes: destRowBytes)
            vImageConvert_PlanarFtoPlanar16F(&source, &dest, 0)
            
            let region = MTLRegionMake2D(0, 0, width, height)
            velocity.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &outputGrid,
                                    bytesPerRow: destRowBytes)
        }
    }
    
    private func createPressureInitialState() {
        switch type(of: self).floatFormat {
        case .float:
            var initialGrid: [Float] = Array(repeating: 0, count: width * height)
            let region = MTLRegionMake2D(0, 0, width, height)
            let rowBytes = MemoryLayout<Float>.size * width
            pressure.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid,
                                    bytesPerRow: rowBytes)
        case .half:
            var initialGrid: [UInt16] = Array(repeating: 0, count: width * height)
            let region = MTLRegionMake2D(0, 0, width, height)
            let rowBytes = MemoryLayout<UInt16>.size * width
            pressure.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid,
                                    bytesPerRow: rowBytes)
        }
    }
    
    private func createDensityInitialState() {
        let range = Fluid.range
        var initialGrid: [Float] = Array(repeating: 0, count: width * height * Fluid.densityComponents)
        for i in 0..<height {
            for j in 0..<width {
                if((i >= height/2 - range && i <= height/2 + range)
                   && (j >= width/2 - range && j <= width/2 + range)){
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 1] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 2] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 3] = 1.0
                }
                else{
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 1] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 2] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 3] = 1.0
                }
            }
        }
        switch type(of: self).floatFormat {
        case .float:
            let region = MTLRegionMake2D(0, 0, width, height)
            density.source.replace(region: region,
                                   mipmapLevel: 0,
                                   withBytes: &initialGrid,
                                   bytesPerRow: MemoryLayout<Float>.size * width * Fluid.densityComponents)
        case .half:
            var outputGrid: [UInt16] = Array(repeating: 0, count: width * height * Fluid.densityComponents)
            let sourceRowBytes = MemoryLayout<Float>.size * width * Fluid.densityComponents
            let destRowBytes = MemoryLayout<UInt16>.size * width * Fluid.densityComponents
            var source = vImage_Buffer(data: &initialGrid, height: UInt(height), width: UInt(width * Fluid.densityComponents), rowBytes: sourceRowBytes)
            var dest = vImage_Buffer(data: &outputGrid, height: UInt(height), width: UInt(width * Fluid.densityComponents), rowBytes: destRowBytes)
            vImageConvert_PlanarFtoPlanar16F(&source, &dest, 0)
            
            let region = MTLRegionMake2D(0, 0, width, height)
            density.source.replace(region: region,
                                   mipmapLevel: 0,
                                   withBytes: &outputGrid,
                                   bytesPerRow: destRowBytes)
        }
    }
}
