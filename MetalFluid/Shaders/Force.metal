//
//  Force.metal
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/17.
//

#include <metal_stdlib>
using namespace metal;

kernel void addForce_X(texture2d<float, access::read>  inVTexture  [[ texture(0) ]],
                  texture2d<float, access::write> outVTexture [[ texture(1) ]],
                     texture2d<float, access::read> FTexture [[ texture(2) ]],
                  uint2 /*(x=0; x<= Nx+1)(y=0; y<= Ny)*/gid [[ thread_position_in_grid ]],
                  constant float &timeStep [[buffer(0)]]
                  ){
    float timestep = timeStep;
    if(gid[0] == 0 || gid[0] == inVTexture.get_width())return;
    float col;
    float4 inVelocity = inVTexture.read(gid);
    uint2 fr = {gid[0] - 1,gid[1]};
    float4 Force = (FTexture.read(gid) + FTexture.read(fr)) / 2;
    col = inVelocity.x + Force.x * timestep;
    outVTexture.write(col, gid);
}
kernel void addForce_Y(texture2d<float, access::read>  inVTexture  [[ texture(0) ]],
                  texture2d<float, access::write> outVTexture [[ texture(1) ]],
                     texture2d<float, access::read> FTexture [[ texture(2) ]],
                  uint2 /*(x=0; x<= Nx)(y=0; y<= Ny+1)*/gid [[ thread_position_in_grid ]],
                  constant float &timeStep [[buffer(0)]]
                  ){
    float timestep = timeStep;
    if(gid[1] == 0 || gid[1] == inVTexture.get_width())return;
    float col;
    float4 inVelocity = inVTexture.read(gid);
    uint2 fr = {gid[0] ,gid[1] - 1};
    float4 Force = (FTexture.read(gid) + FTexture.read(fr)) / 2;
    col = inVelocity.x + Force.y * timestep;
    outVTexture.write(col, gid);
    
}

kernel void calForce(texture2d<float, access::write> outFTexture [[ texture(0) ]],
                     texture2d<float, access::read> RTexture [[ texture(1) ]],
                     texture2d<float, access::read> R_ambTexture [[ texture(2) ]],
                     texture2d<float, access::read> TTexture [[ texture(3) ]],
                  uint2                     gid [[ thread_position_in_grid ]],
                  constant float &T_amb [[buffer(0)]]
                  ){
    float g0 = 9.8;
    float beta = 50;
    float t_amb = T_amb;
    float scale = 0.1;
    float2 dir_gravity = {0.0,1.0};
    float rho = RTexture.read(gid).x;
    float rho_amb = R_ambTexture.read(gid).x;
    float temp = TTexture.read(gid).x;
    float2 gravity = g0*(rho +rho_amb)*dir_gravity;
    float2 buoyancy = -beta*(temp - t_amb)*dir_gravity;
    float2 col = scale * (gravity + buoyancy);
    outFTexture.write(float4(col.x,col.y,0.0,1.0), gid);
}
