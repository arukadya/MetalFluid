#include <metal_stdlib>
using namespace metal;
#define AA 2
typedef struct
{
    packed_float2 position;
    packed_float2 texCoords;
} VertexIn;

typedef struct {
    float4 position [[position]];
    float2 texCoords;
} FragmentVertex;

vertex FragmentVertex vertexShader(device VertexIn *vertexArray [[buffer(0)]],
                             uint vertexIndex [[vertex_id]])
{
    FragmentVertex out;
    out.position = float4(vertexArray[vertexIndex].position, 0, 1);
    out.texCoords = vertexArray[vertexIndex].texCoords;
    return out;
}

fragment float4 fragmentShader(FragmentVertex in [[stage_in]],
                        texture2d<float, access::sample> gameGrid [[texture(0)]])
{
    constexpr sampler nearestSampler(coord::normalized, filter::nearest);
    float4 color = gameGrid.sample(nearestSampler, in.texCoords);
    float4 white = {1.0,1.0,1.0,1.0};
//    return white - color;
    return color;
}

