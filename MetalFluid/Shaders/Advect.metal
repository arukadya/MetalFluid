//
//  Advect.metal
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/17.
//

#include <metal_stdlib>
using namespace metal;

float BiLerp(float2 pos,
             texture2d<float, access::read> target);

kernel void advectVX(texture2d<float, access::read> inVelocityX [[texture(0)]],
                      texture2d<float, access::read> inVelocityY [[texture(1)]],
                   texture2d<float, access::write> outVelocityX [[texture(2)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float timestep = timeStep;
    float2 vGridPos = float2(gridPosition) + float2(0.0,0.5);
    float2 vxGirdPos = vGridPos - float2(0.0,0.5);
    float2 vyGridPos = vGridPos - float2(0.5,0.0);
    float2 lerp_vel = float2(BiLerp(vxGirdPos, inVelocityX), BiLerp(vyGridPos, inVelocityY));
    float2 vGridPos_adv = vGridPos - lerp_vel*timestep;
    float4 newValue = BiLerp(vGridPos_adv - float2(0.0,0.5), inVelocityX);
    outVelocityX.write(newValue, gridPosition);
}

kernel void advectVY(texture2d<float, access::read> inVelocityX [[texture(0)]],
                      texture2d<float, access::read> inVelocityY [[texture(1)]],
                   texture2d<float, access::write> outVelocityY [[texture(2)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float timestep = timeStep;
    float2 vGridPos = float2(gridPosition) + float2(0.0,0.5);
    float2 vxGirdPos = vGridPos - float2(0.0,0.5);
    float2 vyGridPos = vGridPos - float2(0.5,0.0);
    float2 lerp_vel = float2(BiLerp(vxGirdPos, inVelocityX), BiLerp(vyGridPos, inVelocityY));
    float2 vGridPos_adv = vGridPos - lerp_vel*timestep;
    float4 newValue = BiLerp(vGridPos_adv - float2(0.0,0.5), inVelocityY);
    outVelocityY.write(newValue, gridPosition);
}

kernel void advect_Center(texture2d<float, access::read> inVelocityX [[texture(0)]],
                      texture2d<float, access::read> inVelocityY [[texture(1)]],
                          texture2d<float, access::read> source [[texture(2)]],
                   texture2d<float, access::write> target [[texture(3)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float timestep = timeStep;
    float2 vGridPos = float2(gridPosition) + float2(0.5,0.5);
    float2 vxGirdPos = vGridPos - float2(0.0,0.5);
    float2 vyGridPos = vGridPos - float2(0.5,0.0);
    float2 lerp_vel = float2(BiLerp(vxGirdPos, inVelocityX), BiLerp(vyGridPos, inVelocityY));
    float2 vGridPos_adv = vGridPos - lerp_vel*timestep;
    float4 newValue;
    newValue.x = BiLerp(vGridPos_adv - float2(0.5,0.5), source);
    target.write(newValue, gridPosition);
}

float BiLerp(float2 pos,
            texture2d<float, access::read> target){
    uint Nx = target.get_width();
    uint Ny = target.get_height();
    float2 delta = float2(1.0/Nx,1.0/Ny);
    float2 fixedPos = float2(
                             fmax(0.0, fmin(Nx-1-1e-6,pos.x)),
                             fmax(0.0, fmin(Ny-1-1e-6,pos.y))
                             );
    uint2 ij = uint2(pos);
    float s = fixedPos.x - float2(ij).x;
    float t = fixedPos.y - float2(ij).y;
    uint2 readPos[4] = {ij, ij + uint2(1,0), ij + uint2(1,1), ij + uint2(0,1)};
    float4 f = {
        target.read(readPos[0]).x,target.read(readPos[1]).x,target.read(readPos[2]).x,target.read(readPos[3]).x};
    float4 c = {
        (1-s)*(1-t),s*(1-t),s*t,(1-s)*t};
    return dot(f,c);
}

//float TriLinearInterporation(float3 pos,
//                             texture2d<float, access::read> target [[texture(3)]],
//                             uint2 gridPosition [[thread_position_in_grid]],){
//    x = fmax(0.0, fmin(val.nx-1-1e-6,x/dx));
//    y = fmax(0.0, fmin(val.ny-1-1e-6,y/dx));
//    z = fmax(0.0, fmin(val.nz-1-1e-6,z/dx));
//    int i = x;int j = y;int k = z;
//    double s = x-i;double t = y-j;double u = z-k;
//    Eigen::Vector<double,8> f = {
//        val.value[i][j][k],val.value[i+1][j][k],val.value[i+1][j+1][k],val.value[i][j+1][k],
//        val.value[i][j][k+1],val.value[i+1][j][k+1],val.value[i+1][j+1][k+1],val.value[i][j+1][k+1]};
//    Eigen::Vector<double,8> c = {
//        (1-s)*(1-t)*(1-u),s*(1-t)*(1-u),s*t*(1-u),(1-s)*t*(1-u),
//        (1-s)*(1-t)*u,s*(1-t)*u,s*t*u,(1-s)*t*u};
//    return f.dot(c);
//}
