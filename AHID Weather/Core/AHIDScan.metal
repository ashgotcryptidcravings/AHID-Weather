#include <metal_stdlib>
using namespace metal;

// MARK: - Fullscreen vertex pass-through (shared with orb shader)

struct ScanVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex ScanVertexOut scanVertex(uint vid [[vertex_id]]) {
    const float2 pos[4] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0),
        float2(-1.0,  1.0), float2( 1.0,  1.0)
    };
    const float2 uvs[4] = {
        float2(0.0, 1.0), float2(1.0, 1.0),
        float2(0.0, 0.0), float2(1.0, 0.0)
    };
    ScanVertexOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv = uvs[vid];
    return out;
}

// MARK: - Scan line fragment shader
// Renders a glowing horizontal scan beam that sweeps left→right.
// buffer(0): float — progress [0, 1] across the bar width
// buffer(1): float2 — resolution (unused but reserved for consistency)

fragment float4 scanFragment(
    ScanVertexOut in [[stage_in]],
    constant float& progress [[buffer(0)]]
) {
    float x = in.uv.x;

    // Distance from the current scan head position
    float dist = x - progress;

    // Sharp leading edge + soft trailing glow
    float leading  = exp(-max( dist, 0.0) * 60.0);
    float trailing = exp(-max(-dist, 0.0) *  8.0) * 0.25;
    float intensity = leading + trailing;

    // AHID accent purple
    float3 color = float3(0.659, 0.333, 0.969) * intensity;
    return float4(color, intensity);
}
