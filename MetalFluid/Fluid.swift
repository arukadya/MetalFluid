import Foundation
import MetalKit
import Accelerate

enum SurfaceFloatFormat {
    case float, half
}

struct Fluid {
    static let floatFormat: SurfaceFloatFormat = .float
    static let densityComponents: Int = 4
    static let ForceComponents: Int = 4
    static let range: Int = 50
    static let T_amb:Float = 25.0
    let width: Int
    let height: Int
    //let range: Int
    let velocity_x: Slab
    let velocity_y: Slab
    let pressure: Slab
    let density: Slab
    let density_amb: Slab
    let templature:Slab
    let force:Slab
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
        
        guard let velocity_x = device.makeSlab(width: width+1, height: height, format:format, numberOfComponents: 1),
        let velocity_y = device.makeSlab(width: width, height: height+1,
            format:format, numberOfComponents: 1),
        let pressure = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 1),
         let density = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 4),
        let density_amb = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 4),
        let templature = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 1),
        let force = device.makeSlab(width: width, height: height, format:format, numberOfComponents: 2)
        else{
            return nil
        }
        self.velocity_x = velocity_x
        self.velocity_y = velocity_y
        self.pressure = pressure
        self.density = density
        self.density_amb = density_amb
        self.templature = templature
        self.force = force
        self.width = width
        self.height = height
        //self.range = range
        createVelocityInitialState()
        createPressureInitialState()
        createDensityInitialState()
        createDensity_ambInitialState()
        createTemplatureInitialState()
    }
    
    private func createVelocityInitialState() {
//        var initialGrid_x: [Float] = Array(repeating: 0, count: (width + 1) * height * 2)
//        var initialGrid_y: [Float] = Array(repeating: 0, count: (width) * (height + 1) * 2)
        var initialGrid_x: [Float] = Array(repeating: 0, count: (width + 1) * height)
        var initialGrid_y: [Float] = Array(repeating: 0, count: (width) * (height + 1))
//        for i in 0..<height {
//            for j in 0..<width+1 {
//                initialGrid_x[j + i*(width+1)] = 0.0;
//            }
//        }
//        for i in 0..<height+1 {
//            for j in 0..<width {
//                if(j == width - 1){
//                    initialGrid_y[j + i*width] = -1.0;
//                }
//                else{
//                    initialGrid_y[j + i*width] = 0.0;
//                }
//            }
//        }
        switch type(of: self).floatFormat {
        case .float:
            var region = MTLRegionMake2D(0, 0, width+1, height)
//            var rowBytes = MemoryLayout<Float>.size * (width + 1) * 2
            var rowBytes = MemoryLayout<Float>.size * (width + 1)
            velocity_x.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid_x,
                                    bytesPerRow: rowBytes)
            region = MTLRegionMake2D(0, 0, width, height+1)
//            rowBytes = MemoryLayout<Float>.size * width * 2
            rowBytes = MemoryLayout<Float>.size * width
            velocity_y.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid_y,
                                    bytesPerRow: rowBytes)
        case .half:
//            var outputGrid: [UInt16] = Array(repeating: 0, count: width * height * 2)
//            var outputGrid_x: [UInt16] = Array(repeating: 0, count: (width + 1)* height * 2)
//            var outputGrid_y: [UInt16] = Array(repeating: 0, count: (width)* (height + 1) * 2)
            var outputGrid_x: [UInt16] = Array(repeating: 0, count: (width + 1) * height)
            var outputGrid_y: [UInt16] = Array(repeating: 0, count: (width) * (height + 1))
            
//            let sourceRowBytes = MemoryLayout<Float>.size * (width + 1) * 2
//            let destRowBytes = MemoryLayout<UInt16>.size * (width + 1) * 2
            var sourceRowBytes = MemoryLayout<Float>.size * (width + 1)
            var destRowBytes = MemoryLayout<UInt16>.size * (width + 1)
//            var source = vImage_Buffer(data: &initialGrid_x, height: UInt(height), width: UInt(width + 1) * 2, rowBytes: sourceRowBytes)
            var source = vImage_Buffer(data: &initialGrid_x, height: UInt(height), width: UInt(width + 1), rowBytes: sourceRowBytes)
//            var dest = vImage_Buffer(data: &outputGrid_x, height: UInt(height), width: UInt(width + 1) * 2, rowBytes: destRowBytes)
            var dest = vImage_Buffer(data: &outputGrid_x, height: UInt(height), width: UInt(width + 1), rowBytes: destRowBytes)
            vImageConvert_PlanarFtoPlanar16F(&source, &dest, 0)
            
            var region = MTLRegionMake2D(0, 0, (width + 1), height)
            velocity_x.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &outputGrid_x,
                                    bytesPerRow: destRowBytes)
            sourceRowBytes = MemoryLayout<Float>.size * width
            destRowBytes = MemoryLayout<UInt16>.size * width

            source = vImage_Buffer(data: &initialGrid_y, height: UInt(height + 1), width: UInt(width), rowBytes: sourceRowBytes)

            dest = vImage_Buffer(data: &outputGrid_y, height: UInt(height + 1), width: UInt(width), rowBytes: destRowBytes)
            vImageConvert_PlanarFtoPlanar16F(&source, &dest, 0)
            
            region = MTLRegionMake2D(0, 0, width, height + 1)
            velocity_y.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &outputGrid_y,
                                    bytesPerRow: destRowBytes)
        }
    }
    private func createPressureInitialState() {
        switch type(of: self).floatFormat {
        case .float:
            var initialGrid: [Float] = Array(repeating: 0, count: width * height)
            for i in 0..<height {
                for j in 0..<width {
                    initialGrid[j + i*(width)] = 0.0;
                }
            }
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
                if((i >= height/3 * 2 - range && i <= height/3 * 2 + range)
                   && (j >= width/2 - range && j <= width/2 + range)){
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents] = 0/255
                    initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 1] = 255/255
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
    private func createDensity_ambInitialState() {
        let range = Fluid.range
        var initialGrid: [Float] = Array(repeating: 0, count: width * height * Fluid.densityComponents)
        for i in 0..<height {
            for j in 0..<width {
                initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents] = 0/255
                initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 1] = 127/255
                initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 2] = 0/255
                initialGrid[j*Fluid.densityComponents + i*width*Fluid.densityComponents + 3] = 1.0
            }
        }
        switch type(of: self).floatFormat {
        case .float:
            let region = MTLRegionMake2D(0, 0, width, height)
            density_amb.source.replace(region: region,
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
            density_amb.source.replace(region: region,
                                   mipmapLevel: 0,
                                   withBytes: &outputGrid,
                                   bytesPerRow: destRowBytes)
        }
    }
    private func createTemplatureInitialState() {
        let range = Fluid.range
        switch type(of: self).floatFormat {
        case .float:
            print("float")
            var initialGrid: [Float] = Array(repeating: 0, count: width * height)
            for i in 0..<height {
                for j in 0..<width {
                    if((i >= height/3 * 2 - range && i <= height/3 * 2 + range)
                       && (j >= width/2 - range && j <= width/2 + range)){
                        initialGrid[j + i*(width)] = 100;
                    }
                    else{
                        initialGrid[j + i*(width)] = 25;
                    }
                }
            }
            let region = MTLRegionMake2D(0, 0, width, height)
            let rowBytes = MemoryLayout<Float>.size * width
            templature.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid,
                                    bytesPerRow: rowBytes)
        case .half:
            print("half")
            var initialGrid: [UInt16] = Array(repeating: 0, count: width * height)
            for i in 0..<height {
                for j in 0..<width {
                    if((i >= height - range * 2 && i <= height)
                       && (j >= width/2 - range && j <= width/2 + range)){
                        initialGrid[j + i*(width)] = 10/255;
                    }
                }
            }
            let region = MTLRegionMake2D(0, 0, width, height)
            let rowBytes = MemoryLayout<UInt16>.size * width
            templature.source.replace(region: region,
                                    mipmapLevel: 0,
                                    withBytes: &initialGrid,
                                    bytesPerRow: rowBytes)
        }
    }
}
