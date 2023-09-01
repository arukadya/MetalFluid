#include <metal_stdlib>
using namespace metal;
#define AA 2

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texCoords;
};

vertex ColorInOut vertexShader(constant float4 *positions [[ buffer(0) ]],
                               constant float2 *texCoords [[ buffer(1) ]],
                                        uint    vid       [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    out.texCoords = texCoords[vid];
    return out;
}

fragment float4 fragmentShader(ColorInOut       in      [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]])
{
    constexpr sampler colorSampler;
    float4 color = texture.sample(colorSampler, in.texCoords);
    return color;
}

kernel void computeShader(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
              texture2d<float, access::write> outTexture [[ texture(1) ]],
              uint2                     gid [[ thread_position_in_grid ]])
{
    float4 inColor = inTexture.read(gid);
    float4 white = (1,1,1,1);
    outTexture.write(white-inColor, gid);
}

float mandelbrot(float2 c,float time);

kernel void chaos(texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                  texture2d<float, access::write> outTexture [[ texture(1) ]],
                  uint2                     gid [[ thread_position_in_grid ]],
                  constant float2 &resolution [[buffer(0)]],
                  constant float &timeStep
                  ){
    float4 col = float4(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
//        float2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+float2(float(m),float(n))/float(AA)))/resolution.y;
//        float2 p;
//        p.x = (-resolution.x + 2.0*(gid.x+(float)(float(m),float(n))/float(AA)))/resolution.y;
//        p.y = (-resolution.y + 2.0*(gid.y+(float)(float(m),float(n))/float(AA)))/resolution.y;
        float2 p = (-resolution.xy + 2.0*((float2)gid.xy+float2(float(m),float(n))/float(AA)))/resolution.x;
//
        float w = float(AA*m+n);
        float time = timeStep + 0.5*(1.0/24.0)*w/float(AA*AA);
        
#else
        float2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.x;
        float time = timeStep;
#endif
    
        float zoo = 0.62 + 0.38*cos(.07*time);
        float coa = cos( 0.15*(1.0-zoo)*time );
        float sia = sin( 0.15*(1.0-zoo)*time );
        zoo = pow( zoo,8.0);
        float2 xy = float2( p.x*coa-p.y*sia, p.x*sia+p.y*coa);
        float2 c = float2(-.745,.186) + xy*zoo;

        float l = mandelbrot(c,time);

        col += 0.5 + 0.5*cos( 3.0 + l*0.15 + float4(0.0,0.6,1.0,1.0));
#if AA>1
    }
    col /= float(AA*AA);
#endif

//    gl_FragColor = float4( col, 1.0 );
//    return float4( col, 1.0 );
    outTexture.write(col, gid);
}

float mandelbrot( float2 c ,float time)
{
    #if 1
    {
        float c2 = dot(c, c);
        // skip computation inside M1 - https://iquilezles.org/articles/mset1bulb
        if( 256.0*c2*c2 - 96.0*c2 + 32.0*c.x - 3.0 < 0.0 ) return 0.0;
        // skip computation inside M2 - https://iquilezles.org/articles/mset2bulb
        if( 16.0*(c2+2.0*c.x+1.0) - 1.0 < 0.0 ) return 0.0;
    }
    #endif


    const float B = 256.0;
    float l = 0.0;
    float2 z  = float2(0.0);
    for( int i=0; i<512; i++ )
    {
        z = float2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
        if( dot(z,z)>(B*B) ) break;
        l += 1.0;
    }

    if( l>511.0 ) return 0.0;
    
    // ------------------------------------------------------
    // smooth interation count
    //float sl = l - log(log(length(z))/log(B))/log(2.0);

    // equivalent optimized smooth interation count
    float sl = l - log2(log2(dot(z,z))) + 4.0;

    float al = smoothstep( -0.1, 0.0, sin(0.5*6.2831*time ) );
    l = mix( l, sl, al );

    return l;
}
