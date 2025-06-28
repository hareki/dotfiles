// cursor_fade_trail.glsl
//
// Minimal blaze-style cursor trail for Ghostty.
//
// – Trail colour & blend identical to cursor_blaze.glsl
// – No accent/glow – the terminal’s own cursor is left untouched
// – All uniforms and helper functions remain 100 % Shadertoy-compatible
//
// Author: your beloved ChatGPT o3 and KroneCorylus/shader-playground

// ────────────────────────────────────────────────────────────────
// Helpers (unchanged from cursor_blaze)
// ────────────────────────────────────────────────────────────────
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w,e)/dot(e,e), 0.0, 1.0);
    d = min(d, dot(p - proj, p - proj));

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float flip = mix(1.0, -1.0, step(0.5, c0*c1*c2 + (1.0-c0)*(1.0-c1)*(1.0-c2)));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1,
                          in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);
    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);
    return s * sqrt(d);
}

vec2 normalize(in vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float blend(float t) {       // same non-linear ease as blaze
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

float antialias(in float d) {
    return 1.0 - smoothstep(0.0, normalize(vec2(2.0),0.0).x, d);
}

float startVertexFactor(vec2 a, vec2 b) {
    float c1 = step(b.x,a.x)*step(a.y,b.y);
    float c2 = step(a.x,b.x)*step(b.y,a.y);
    return 1.0 - max(c1,c2);
}

vec2 rectCenter(vec4 r) {           // r = (x,y,w,h) in NDC
    return vec2(r.x + r.z*0.5, r.y - r.w*0.5);
}

// ────────────────────────────────────────────────────────────────
// Tunables
// ────────────────────────────────────────────────────────────────
const vec4  TRAIL_COLOR = vec4(0.498, 0.518, 0.612, 1.0); // #7f849c Overlay1
const float DURATION    = 0.22;                         // seconds

// ────────────────────────────────────────────────────────────────
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Base terminal frame (already contains the normal cursor)
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    vec4 baseColor = fragColor;

    // Normalised pixel coord (-1…1 on short edge)
    vec2 p = normalize(fragCoord, 1.0);
    vec2 offset = vec2(-0.5, 0.5);                     // centre origin

    // Current & previous cursor rectangles in NDC
    vec4 cur = vec4(normalize(iCurrentCursor.xy,1.0),
                    normalize(iCurrentCursor.zw,0.0));
    vec4 prev = vec4(normalize(iPreviousCursor.xy,1.0),
                     normalize(iPreviousCursor.zw,0.0));

    // Parallelogram vertices for the trail
    float vFactor  = startVertexFactor(cur.xy, prev.xy);
    float ivFactor = 1.0 - vFactor;
    vec2 v0 = vec2(cur.x + cur.z*vFactor,  cur.y - cur.w);
    vec2 v1 = vec2(cur.x + cur.z*ivFactor, cur.y);
    vec2 v2 = vec2(prev.x + cur.z*ivFactor, prev.y);
    vec2 v3 = vec2(prev.x + cur.z*vFactor,  prev.y - prev.w);

    // Signed–distance fields
    float sdfTrail   = getSdfParallelogram(p, v0, v1, v2, v3);
    float sdfCursor  = getSdfRectangle(p, cur.xy - cur.zw*offset, cur.zw*0.5);

    // Temporal easing (same as blaze)
    float prog       = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0));

    // Alpha fall-off along the trail
    float len        = distance(rectCenter(cur), rectCenter(prev));
    float alphaMod   = distance(p, rectCenter(cur)) / max(len * (1.0 - prog), 1e-4);

    // ─── Draw trail ────────────────────────────────────────────
    vec4 col = baseColor;
    col = mix(col, TRAIL_COLOR, 1.0 - smoothstep(sdfTrail, -0.01, 0.001));
    col = mix(col, TRAIL_COLOR, antialias(sdfTrail));
    col = mix(baseColor, col, clamp(1.0 - alphaMod, 0.0, 1.0));

    // Leave the actual cursor untouched (minimalism!)
    fragColor = mix(col, baseColor, step(sdfCursor, 0.0));
}
