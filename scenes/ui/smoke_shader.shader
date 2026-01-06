shader_type canvas_item;

// Smoke shader for atmospheric intro sequence
// Creates drifting, layered smoke effect using Perlin-style noise

uniform float time_scale : hint_range(0.0, 2.0) = 0.15;
uniform float smoke_density : hint_range(0.0, 1.0) = 0.6;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.3;
uniform vec3 smoke_color = vec3(0.3, 0.3, 0.35);

// Simple 2D noise function (procedural Perlin-style)
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for layered noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 3; i++) {  // Reduced from 7 to 3 layers for performance
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;
    
    // Create drifting smoke layers - REDUCED TO 2 LAYERS
    vec2 drift = vec2(time * drift_speed, time * drift_speed * 0.3);
    
    // Only 2 smoke layers instead of 3
    float smoke1 = fbm(uv * 3.0 + drift);
    float smoke2 = fbm(uv * 5.0 - drift * 0.7);
    
    // Combine layers
    float smoke = (smoke1 + smoke2 * 0.6) / 1.6;
    
    // Apply density control
    smoke = smoothstep(1.0 - smoke_density, 1.0, smoke);
    
    // Darker at top, lighter at bottom (atmosphere effect)
    float vignette = smoothstep(0.0, 0.5, uv.y);
    smoke *= vignette * 0.7 + 0.3;
    
    // Output
    vec3 final_color = smoke_color * smoke;
    COLOR = vec4(final_color, smoke);
}
