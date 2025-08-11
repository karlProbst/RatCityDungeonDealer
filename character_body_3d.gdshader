shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D dither_texture : repeat_enable, filter_nearest;

uniform int pixel_size_near : hint_range(1,64) = 1;
uniform int pixel_size_far : hint_range(1,64) = 8;
uniform int color_steps_near : hint_range(2,32) = 32;
uniform int color_steps_far : hint_range(2,32) = 8;

uniform float dither_intensity_near : hint_range(0.0,1.0) = 0.0;
uniform float dither_intensity_far : hint_range(0.0,1.0) = 0.7;

uniform float near_distance : hint_range(0.0,1.0) = 0.2;
uniform float far_distance : hint_range(0.0,1.0) = 0.8;

void fragment() {
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float dist_factor = smoothstep(near_distance, far_distance, depth);

    float pixel_size = mix(float(pixel_size_near), float(pixel_size_far), dist_factor);
    float color_steps = mix(float(color_steps_near), float(color_steps_far), dist_factor);
    float dither_intensity = mix(dither_intensity_near, dither_intensity_far, dist_factor);

    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 pixel_uv = floor(SCREEN_UV * screen_size / pixel_size) * pixel_size / screen_size;

    vec3 col = texture(SCREEN_TEXTURE, pixel_uv).rgb;

    float step_size = 1.0 / color_steps;

    vec2 dither_uv = FRAGCOORD.xy / pixel_size;
    float threshold = texture(dither_texture, dither_uv).r;
    threshold = mix(0.5, threshold, dither_intensity);

    vec3 final_col;
    for(int i = 0; i < 3; i++) {
        float val = col[i];
        float quant = floor(val * color_steps) / color_steps;
        float diff = val - quant;
        final_col[i] = (diff > threshold * step_size) ? min(quant + step_size, 1.0) : quant;
    }

    EMISSION = final_col;
}
