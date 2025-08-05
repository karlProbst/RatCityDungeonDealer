shader_type canvas_item;

// Godot 4.x post-process screen texture
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Dither texture (should be set to repeat with nearest filtering)
uniform sampler2D u_dither_tex : repeat_disable, filter_nearest;

// Controls
uniform int u_color_steps = 4;  // Number of color steps per channel (1 = full reduction)
uniform int u_dither_size = 4;  // Pixelation size
uniform float u_dither_intensity = 1.0; // Control dither strength

void fragment()
{
    // Pixelate screen
    vec2 screen_pixel_size = vec2(textureSize(SCREEN_TEXTURE, 0)) / float(u_dither_size);
    vec2 sample_uv = floor(UV * screen_pixel_size) / screen_pixel_size;
    vec3 screen_col = texture(SCREEN_TEXTURE, sample_uv).rgb;
    
    // Color quantization (reduce number of colors)
    vec3 quantized_col;
    if (u_color_steps > 1) {
        quantized_col = floor(screen_col * float(u_color_steps) + 0.5) / float(u_color_steps);
    } else {
        // Extreme color reduction
        quantized_col = floor(screen_col + 0.5);
    }
    
    // Calculate dither pattern UVs (scaled to screen pixelation and repeated)
    vec2 dither_uv = FRAGCOORD.xy / float(u_dither_size);
    float threshold = texture(u_dither_tex, dither_uv).r;
    
    // Adjust dither intensity
    threshold = mix(0.5, threshold, u_dither_intensity);
    
    // Apply dithering to each color channel
    vec3 final_col;
    float step_size = 1.0 / float(u_color_steps);
    
    for (int i = 0; i < 3; i++) {
        float col_value = screen_col[i];
        float quantized = quantized_col[i];
        float dither_diff = col_value - quantized;
        
        // Apply dithering with threshold
        final_col[i] = (dither_diff > threshold * step_size) ? 
            min(quantized + step_size, 1.0) : 
            quantized;
    }
    
    COLOR.rgb = final_col;
}