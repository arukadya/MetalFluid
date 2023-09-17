//
//  Advect.metal
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/17.
//

#include <metal_stdlib>
using namespace metal;



kernel void advectVX(texture2d<float, access::sample> inVelocityX [[texture(0)]],
                      texture2d<float, access::sample> inVelocityY [[texture(1)]],
                   texture2d<float, access::write> outVelocityX [[texture(2)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float timestep = timeStep;
    float2 vGridPos = float2(gridPosition) + float2(0.0,0.5);
    float2 vNxNy = float2(inVelocityX.get_width(), inVelocityX.get_height());
    float2 vXYPos = vGridPos.xy / vNxNy.xy;
//    constexpr sampler s(coord::normalized,
//                        address::clamp_to_border,
//                        filter::linear);
    constexpr sampler s0(address::clamp_to_border,
                        filter::linear);
//    constexpr sampler sn(coord::normalized,
//                         address::clamp_to_border,
//                        filter::linear);
    constexpr sampler sn(coord::normalized,
                         address::clamp_to_zero,
                        filter::linear);
//    float2 velocityPos_adv = velocityPos_in - inVelocityX.sample(s, float2(gridPosition)).xy/frame*timeStep;
    float2 vxXYPos = vXYPos - float2(0.0,0.5)/vNxNy.xy;
    float2 vyXYPos = vXYPos - float2(0.5,0.0)/vNxNy.xy;
    float2 sampled_vel = float2(inVelocityX.sample(sn, vxXYPos).x,inVelocityY.sample(sn, vyXYPos).x);
    float2 vXYPos_adv = vXYPos - sampled_vel*timestep;
    float4 newValue = inVelocityX.sample(sn, (vXYPos_adv - float2(0.0,0.5)/vNxNy.xy));
    outVelocityX.write(newValue, gridPosition);
}

kernel void advectVY(texture2d<float, access::sample> inVelocityX [[texture(0)]],
                      texture2d<float, access::sample> inVelocityY [[texture(1)]],
                   texture2d<float, access::write> outVelocityY [[texture(2)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float timestep = timeStep;
    float2 vGridPos = float2(gridPosition) + float2(0.5,0.0);
    float2 vNxNy = float2(inVelocityY.get_width(), inVelocityY.get_height());
    float2 vXYPos = vGridPos.xy / vNxNy.xy;
//    constexpr sampler s(coord::normalized,
//                        address::clamp_to_border,
//                        filter::linear);
    constexpr sampler s(address::clamp_to_border,
                        filter::linear);
//    constexpr sampler sn(coord::normalized,
//                         address::clamp_to_border,
//                        filter::linear);
    constexpr sampler sn(coord::normalized,
                         address::clamp_to_zero,
                        filter::linear);
//    float2 velocityPos_adv = velocityPos_in - inVelocityX.sample(s, float2(gridPosition)).xy/frame*timeStep;
    float2 vxXYPos = vXYPos - float2(0.0,0.5)/vNxNy.xy;
    float2 vyXYPos = vXYPos - float2(0.5,0.0)/vNxNy.xy;
    float2 vxGridPos = vGridPos - float2(0.0,0.5);
    float2 vyGridPos = vGridPos - float2(0.5,0.0);
    float2 sampled_vel = float2(inVelocityX.sample(sn, vxXYPos).x,inVelocityY.sample(sn, vyXYPos).x);
//    sampled_vel = float2(inVelocityX.sample(sn,vxGridPos).x,inVelocityY.sample(sn, vyGridPos).x);
    float2 vXYPos_adv = vXYPos - sampled_vel*timestep;
    float2 vGridPos_adv = vXYPos - sampled_vel*timestep;
    float4 newValue = inVelocityY.sample(sn, (vXYPos_adv - float2(0.5,0.0)/vNxNy.xy));
//    newValue = inVelocityY.sample(sn, (vGridPos_adv - float2(0.5,0.0)));
    outVelocityY.write(newValue, gridPosition);
}

kernel void advect_Center(texture2d<float, access::sample> inVelocityX [[texture(0)]],
                      texture2d<float, access::sample> inVelocityY [[texture(1)]],
                          texture2d<float, access::sample> source [[texture(2)]],
                   texture2d<float, access::write> target [[texture(3)]],
                   uint2 gridPosition [[thread_position_in_grid]],
                   constant float &timeStep [[buffer(0)]])
{
    float2 vGridPos = float2(gridPosition) + float2(0.5,0.5);
    float2 vNxNy = float2(source.get_width(), source.get_height());
    float2 vXYPos = vGridPos.xy / vNxNy.xy;
    constexpr sampler s0(address::clamp_to_zero,
                        filter::linear);
//    constexpr sampler sn(coord::normalized,
//                        address::clamp_to_border,
//                        filter::linear);
    constexpr sampler sn(coord::normalized,
                        address::clamp_to_zero,
                        filter::linear);
    float2 vxXYPos = vXYPos - float2(0.0,0.5)/vNxNy.xy;
    float2 vyXYPos = vXYPos - float2(0.5,0.0)/vNxNy.xy;
    float2 sampled_vel = float2(inVelocityX.sample(sn, vxXYPos).x,inVelocityY.sample(sn, vyXYPos).x);
    float2 sourceXYPos_adv = vXYPos - sampled_vel*timeStep;
    float4 newValue = source.sample(sn, sourceXYPos_adv - float2(0.5,0.5)/vNxNy.xy);
    target.write(newValue, gridPosition);
}

float BiLerp(float2 pos,
            texture2d<float, access::sample> target){
    uint Nx = target.get_width();
    uint Ny = target.get_height();
    float2 delta = float2(1.0/Nx,1.0/Ny);
    float2 fixedPos = fmax(0.0, fmin(delta-1-1e-6,pos/delta));
    uint2 ij = uint2(pos);
    float s = fixedPos.x - float2(ij).x;
    float t = fixedPos.y - float2(ij).y;
    uint2 samplePos[4] = {ij, ij + uint2(1,0), ij + uint2(1,1), ij + uint2(0,1)};
    float4 f = {
        target.read(samplePos[0]).x,target.read(samplePos[1]).x,target.read(samplePos[2]).x,target.read(samplePos[3]).x};
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
