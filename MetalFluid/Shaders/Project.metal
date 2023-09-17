//
//  Project.metal
//  MetalFluid
//
//  Created by 須之内俊樹 on 2023/09/17.
//

#include <metal_stdlib>
using namespace metal;

kernel void project(texture2d<float, access::read> inPressure [[texture(0)]],
                    texture2d<float, access::read> VelocityX [[texture(1)]],
                    texture2d<float, access::read> VelocityY [[texture(2)]],
                    texture2d<float, access::read> Density [[texture(3)]],
                    texture2d<float, access::read> Density_amb [[texture(4)]],
                    texture2d<float, access::write> outPressure [[texture(5)]],
                 uint2 gridPosition [[thread_position_in_grid]],
                 constant float &timeStep [[buffer(0)]]){
    float dt = timeStep;
    uint Nx = Density.get_width();
    uint Ny = Density.get_height();
    float2 delta = float2(1.0/Density.get_width(),1.0/Density.get_height());
    float rho_tgt = Density.read(gridPosition).y;
    float rho_amb = Density_amb.read(gridPosition).y;
    float rho = rho_tgt + rho_amb;
    float scale = dt/(rho*delta.x*delta.y);//左辺の係数部分
    float4 col = float4(0.0);
//    float eps = 1.0e-4;//ガウスザイデル法の精度
//    float err;//ガウスザイデル法の残差
//    do{
    float4 D = float4(1.0,1.0,-1.0,-1.0);//周囲4方向に向かって働く、圧力の向き
    uint i = gridPosition.x;
    uint j = gridPosition.y;
    float4 F = float4((float)(i<Nx-1),(float)(j<Ny-1),(float)(i>0),(float)(j>0));//境界条件。壁なら0,流体なら1
    float P[4] = {//pn。周囲4つのセルの圧力値
        (F[0] ? inPressure.read(uint2(i+1,j)).x : 0.0),
        (F[1] ? inPressure.read(uint2(i,j+1)).x : 0.0),
        (F[2] ? inPressure.read(uint2(i-1,j)).x : 0.0),
        (F[3] ? inPressure.read(uint2(i,j-1)).x : 0.0)};
    
//        float U[4] = {u[i+1][j],v[i][j+1],u[i][j],v[i][j]};
    float4 U = float4(VelocityX.read(uint2(i+1,j)).x,VelocityY.read(uint2(i,j+1)).x,VelocityX.read(uint2(i,j)).x,VelocityY.read(uint2(i,j)).x);
    //セルの圧力値を求める
    float det = 0.0;//左辺のdeterminant
    int sumF = 0;
    float sum_L = 0.0;
    float sum_R = 0.0;
    for(int n=0;n<4;n++){
        sumF += F[n];
        det += F[n]*scale;
        sum_L += F[n]*P[n]*scale;
        sum_R += F[n]*D[n]*U[n]/delta.x;
    }
    //if(sumF == 0)col = 0;
    col = (sum_L-sum_R)/det;
    outPressure.write(col, gridPosition);
}
//    }while(eps<err);//反復回数は初期値と収束速度？に依存。定数回なら全体で計算量はO(n)
//    for(int i=1; i<Nx;i++)for(int j=0;j<Ny;j++){
//        if(mi[i][j] < eps)u[i][j] =u[i][j] = u[i][j] - dt/rho * (p[i][j]-p[i-1][j])/delta.x;
//        else u[i][j] = u[i][j] - dt/rho * (p[i][j]-p[i-1][j])/delta.x + dt*fi[i][j].x()/mi[i][j];
//    }
//    for(int i=0; i<Nx;i++)for(int j=1;j<Ny;j++){
//        if(mi[i][j] < eps)v[i][j] = v[i][j] - dt/rho * (p[i][j]-p[i][j-1])/delta.x;
//        else v[i][j] = v[i][j] - dt/rho * (p[i][j]-p[i][j-1])/delta.x + dt*fi[i][j].y()/mi[i][j];
//    }
kernel void divergenceX(
                        texture2d<float, access::read> inVelocityX [[texture(0)]],
                        texture2d<float, access::read> Pressure [[texture(1)]],
                    texture2d<float, access::read> Density [[texture(2)]],
                    texture2d<float, access::read> Density_amb [[texture(3)]],
                    texture2d<float, access::write> outVelocityX [[texture(4)]],
                 uint2 gridPosition [[thread_position_in_grid]],
                        constant float &timeStep [[buffer(0)]]){
    float dt = timeStep;
    uint Nx = inVelocityX.get_width();
    uint Ny = inVelocityX.get_height();
    float2 delta = float2(1.0/Density.get_width(),1.0/Density.get_height());
    float rho_tgt = Density.read(gridPosition).y;
    float rho_amb = Density_amb.read(gridPosition).y;
    float rho = rho_tgt + rho_amb;
    if(gridPosition.x == 0 || gridPosition.x == Nx-1){
        return;
    }
    float p = Pressure.read(gridPosition).x;
    float p_prev = Pressure.read(uint2
                                 (gridPosition.x - 1 ,gridPosition.y)).x;
    float4 col = float4(0.0);
    col.x = inVelocityX.read(gridPosition).x - dt/rho * (p-p_prev)/delta.x;
//    for(uint i=0; i<Nx;i++)for(uint j=1;j<Ny;j++){
//        v[i][j] = v[i][j] - dt/rho * (p[i][j]-p[i][j-1])/delta.x;
//    }
    outVelocityX.write(col, gridPosition);
}
kernel void divergenceY(
                        texture2d<float, access::read> inVelocityY [[texture(0)]],
                        texture2d<float, access::read> Pressure [[texture(1)]],
                    texture2d<float, access::read> Density [[texture(2)]],
                    texture2d<float, access::read> Density_amb [[texture(3)]],
                    texture2d<float, access::write> outVelocityY [[texture(4)]],
                 uint2 gridPosition [[thread_position_in_grid]],
                        constant float &timeStep [[buffer(0)]]){
    float dt = timeStep;
    uint Nx = inVelocityY.get_width();
    uint Ny = inVelocityY.get_height();
    float2 delta = float2(1.0/Density.get_width(),1.0/Density.get_height());
    float rho_tgt = Density.read(gridPosition).y;
    float rho_amb = Density_amb.read(gridPosition).y;
    float rho = rho_tgt + rho_amb;
    if(gridPosition.y == 0 || gridPosition.y == Ny-1){
        return;
    }
    float p = Pressure.read(gridPosition).x;
    float p_prev = Pressure.read(uint2
                                 (gridPosition.x ,gridPosition.y - 1)).x;
    float4 col = float4(0.0);
    col.x = inVelocityY.read(gridPosition).x - dt/rho * (p-p_prev)/delta.x;
//    for(uint i=0; i<Nx;i++)for(uint j=1;j<Ny;j++){
//        v[i][j] = v[i][j] - dt/rho * (p[i][j]-p[i][j-1])/delta.x;
//    }
    outVelocityY.write(col, gridPosition);
}

