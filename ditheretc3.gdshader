shader_type canvas_item;

// === Texturas ===
// Tela atual para post-process
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// Textura de dithering (Bayer ou ruído), usar repeat e filter_nearest
uniform sampler2D u_dither_tex : repeat_enable, filter_nearest;

// === Parâmetros de controle ===
uniform int u_color_steps : hint_range(2,32) = 8;     // Quantização de cores por canal
uniform int u_pixel_size : hint_range(1,64) = 4;      // Tamanho do pixel virtual
uniform float u_dither_intensity : hint_range(0.0,1.0) = 0.5; // Intensidade do dithering
uniform float white_tint : hint_range(0.0,1.0) = 0.0; // Intensidade do dithering

// === Noise parameters ===
uniform float u_noise : hint_range(0.0, 1.0) = 0.0;          // Nível base de ruído

// Função de ruído simples baseada em seno (determinístico)
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // ==== Pixelização ====
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 pixel_uv = floor(UV * screen_size / float(u_pixel_size))
                  * float(u_pixel_size) / screen_size;

    vec3 screen_col = texture(SCREEN_TEXTURE, pixel_uv).rgb;

    // ==== Quantização de cor ====
    vec3 quantized_col = floor(screen_col * float(u_color_steps)) / float(u_color_steps);
    float step_size = 1.0 / float(u_color_steps);

    // ==== Dithering ====
    vec2 dither_uv = FRAGCOORD.xy / float(u_pixel_size);
    float threshold = texture(u_dither_tex, dither_uv).r;
    threshold = mix(0.5, threshold, u_dither_intensity);

    vec3 final_col;
    for (int i = 0; i < 3; i++) {
        float col_value = screen_col[i];
        float quantized = quantized_col[i];
        float dither_diff = col_value - quantized;

        final_col[i] = (dither_diff > threshold * step_size)
            ? min(quantized + step_size, 1.0)
            : quantized;
    }

    // ==== Noise injection ====
    float n = rand(UV * TIME) * u_noise;
    final_col += (n - 0.5) * 0.1; // adiciona ruído leve (0.1 = força máx)

    COLOR.rgb = clamp(final_col/(1.0-white_tint), 0.0, 1.0);
}
