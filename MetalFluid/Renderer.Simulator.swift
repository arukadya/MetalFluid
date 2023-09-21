import Foundation
import MetalKit

extension Renderer {
    class Simulator {
        private weak var device: MTLDevice?
        private var timestep:Float = 0.1
        // Resources
        private(set) var fluid: Fluid
        
        // Commands
        
        private let project: Project
        private let divergenceX: DivergenceX
        private let divergenceY: DivergenceY
        private let advectVX: AdvectVX
        private let advectVY: AdvectVY
        private let advectCenter: AdvectCenter
        private let addForceX: AddForceX
        private let addForceY: AddForceY
        private let calForce: CalForce
        
        
        init?(device: MTLDevice, library: MTLLibrary, width: Int, height: Int) {
            self.device = device
            
            do {
                advectVX = try AdvectVX(device: device, library: library, timestep: timestep)
                advectVY = try AdvectVY(device: device, library: library, timestep: timestep)
                advectCenter = try AdvectCenter(device: device, library: library, timestep: timestep)
                calForce = try CalForce(device: device, library: library)
                addForceX = try AddForceX(device: device, library: library, timestep: timestep)
                addForceY = try AddForceY(device: device, library: library, timestep: timestep)
                project = try Project(device: device, library: library, timestep: timestep)
                divergenceX = try DivergenceX(device: device, library: library, timestep: timestep)
                divergenceY = try DivergenceY(device: device, library: library, timestep: timestep)
                
            } catch {
                print("Failed to create shader program: \(error)")
                return nil
            }
            
            guard let fluid = Fluid(device: device, width: width, height: height) else {
                print("Failed to create Fluid")
                return nil
            }
            
            self.fluid = fluid
        }
        
        func initializeFluid(with width: Int, height: Int) {
            guard let device = device, let fluid = Fluid(device: device, width: width, height: height) else {
                return
            }
            
            self.fluid = fluid
        }

        func encode(in buffer: MTLCommandBuffer) {
            
            calForce.encode(in: buffer, outFTexture: fluid.force.dest, RTexture: fluid.density.source, R_ambTexture: fluid.density_amb.source,TTexture: fluid.templature.source)
            fluid.force.swap()

            addForceX.encode(in: buffer, inVTexture: fluid.velocity_x.source, outVTexture: fluid.velocity_x.dest, FTexture: fluid.force.source)
            addForceY.encode(in: buffer, inVTexture: fluid.velocity_y.source, outVTexture: fluid.velocity_y.dest, FTexture: fluid.force.source)
            fluid.velocity_x.swap()
            fluid.velocity_y.swap()

            project.encode(in: buffer, SPressure: fluid.pressure, VelocityX: fluid.velocity_x.source, VelocityY: fluid.velocity_y.source, Density: fluid.density.source, Density_amb: fluid.density_amb.source)
//            encodeでswapしてるので不要
            divergenceX.encode(in: buffer,inVelocityX: fluid.velocity_x.source, Pressure: fluid.pressure.source, Density: fluid.density.source, Density_amb: fluid.density_amb.source, outVelocityX: fluid.velocity_x.dest)
            divergenceY.encode(in: buffer, inVelocityY: fluid.velocity_y.source, Pressure: fluid.pressure.source, Density: fluid.density.source, Density_amb: fluid.density_amb.source, outVelocityY: fluid.velocity_y.dest)
            fluid.velocity_x.swap()
            fluid.velocity_y.swap()
            
            advectVX.encode(in: buffer, inVelocityX: fluid.velocity_x.source, inVelocityY: fluid.velocity_y.source, outVelocityX: fluid.velocity_x.dest)
            advectVY.encode(in: buffer, inVelocityX: fluid.velocity_x.source, inVelocityY: fluid.velocity_y.source, outVelocityY: fluid.velocity_y.dest)
            fluid.velocity_x.swap()
            fluid.velocity_y.swap()

            
            advectCenter.encode(in: buffer, inVelocityX: fluid.velocity_x.source, inVelocityY: fluid.velocity_y.source, source: fluid.density_amb.source, target: fluid.density_amb.dest)
            advectCenter.encode(in: buffer, inVelocityX: fluid.velocity_x.source, inVelocityY: fluid.velocity_y.source, source: fluid.templature.source, target: fluid.templature.dest)
            advectCenter.encode(in: buffer, inVelocityX: fluid.velocity_x.source, inVelocityY: fluid.velocity_y.source, source: fluid.density.source, target: fluid.density.dest)
            fluid.templature.swap()
            fluid.density.swap()
            fluid.density_amb.swap()

            
//            advect.encode(in:buffer,source: fluid.density.source, dest: fluid.density.dest)
//            fluid.density.swap()
        }
        
        var currentTexture: MTLTexture {
            return fluid.density.source
        }
    }
}
