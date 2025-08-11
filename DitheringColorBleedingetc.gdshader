shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D u_dither_tex : repeat_disable, filter_nearest;

// Color controls
uniform int u_color_steps = 4;
uniform int u_dither_size = 4;
uniform float u_dither_intensity = 1.0;

// Advanced color bleeding
uniform float u_bleed_intensity = 0.5;    // 0-1
uniform float u_bleed_spread = 3.0;       // In pixels
uniform float u_bleed_brightness = 1.2;   // Bleed brightness boost

vec3 advanced_color_bleed(vec2 uv, vec2 pixel_size) {
    // Calculate bleed radius in UV space
    float bleed_radius = u_bleed_spread * pixel_size.x;
    
    // Sample neighbor pixels in a cross pattern
    vec3 right = texture(SCREEN_TEXTURE, uv + vec2(bleed_radius, 0.0)).rgb;
    vec3 left = texture(SCREEN_TEXTURE, uv - vec2(bleed_radius, 0.0)).rgb;
    vec3 up = texture(SCREEN_TEXTURE, uv + vec2(0.0, bleed_radius)).rgb;
    vec3 down = texture(SCREEN_TEXTURE, uv - vec2(0.0, bleed_radius)).rgb;
    
    // Original color
    vec3 center = texture(SCREEN_TEXTURE, uv).rgb;
    
    // Calculate bleed influence (bright pixels bleed more)
    vec3 horizontal_bleed = (left + right) * 0.5;
    vec3 vertical_bleed = (up + down) * 0.5;
    
    // Weight by brightness and intensity
    float brightness = length(center);
    vec3 bleed = mix(horizontal_bleed, vertical_bleed, 0.7);
    bleed = bleed * brightness * u_bleed_brightness;
    
    // Blend with original
    return mix(center, max(center, bleed), u_bleed_intensity * brightness);
}

void fragment() {
    // Base pixelation
    vec2 pixel_size = vec2(textureSize(SCREEN_TEXTURE, 0)) / float(u_dither_size);
    vec2 sample_uv = floor(UV * pixel_size) / pixel_size;
    
    // Apply advanced color bleeding
    vec3 screen_col = advanced_color_bleed(sample_uv, pixel_size);
    
    // Color quantization
    vec3 quantized_col;
    if (u_color_steps > 1) {
        quantized_col = floor(screen_col * float(u_color_steps) + 0.5) / float(u_color_steps);
    } else {
        quantized_col = floor(screen_col + 0.5);
    }
    
    // Dithering
    vec2 dither_uv = FRAGCOORD.xy / float(u_dither_size);
    float threshold = texture(u_dither_tex, dither_uv).r;
    threshold = mix(0.5, threshold, u_dither_intensity);
    
    // Apply dithering to each channel
    vec3 final_col;
    float step_size = 1.0 / float(u_color_steps);
    
    for (int i = 0; i < 3; i++) {
        float col_value = screen_col[i];
        float quantized = quantized_col[i];
        float dither_diff = col_value - quantized;
        final_col[i] = (dither_diff > threshold * step_size) ? 
            min(quantized + step_size, 1.0) : 
            quantized;
    }
    
    COLOR.rgb = final_col;
}