#include <metal_stdlib>
using namespace metal;

// MARK: - Fullscreen vertex pass-through

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut orbVertex(uint vid [[vertex_id]]) {
    // Fullscreen triangle strip (4 verts)
    const float2 pos[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    const float2 uvs[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    VertexOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv = uvs[vid];
    return out;
}

// MARK: - Orb fragment shader
// Renders three soft radial glow orbs matching the SwiftUI background aesthetic.
// resolution: drawable size in points (float2 via buffer 0)

fragment float4 orbFragment(
    VertexOut in [[stage_in]],
    constant float2& resolution [[buffer(0)]]
) {
    float2 px = in.uv * resolution;   // pixel coordinate
    float2 c  = resolution * 0.5;     // screen center

    float3 col = float3(0.0);

    // Orb 1 — deep purple, top-left offset
    float2 p1 = c + float2(-100.0, -200.0);
    float  d1 = length(px - p1);
    float  g1 = pow(max(1.0 - d1 / 150.0, 0.0), 2.5) * 0.045;
    col += float3(0.486, 0.227, 0.929) * g1;

    // Orb 2 — mid purple, right offset
    float2 p2 = c + float2(200.0, 100.0);
    float  d2 = length(px - p2);
    float  g2 = pow(max(1.0 - d2 / 125.0, 0.0), 2.5) * 0.035;
    col += float3(0.659, 0.333, 0.969) * g2;

    // Orb 3 — cool blue, bottom offset
    float2 p3 = c + float2(-50.0, 300.0);
    float  d3 = length(px - p3);
    float  g3 = pow(max(1.0 - d3 / 175.0, 0.0), 2.5) * 0.022;
    col += float3(0.1, 0.2, 1.0) * g3;

    float luma = col.r * 0.299 + col.g * 0.587 + col.b * 0.114;
    return float4(col, luma);
}
