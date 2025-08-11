shader_type spatial;



uniform sampler2D tex_albedo : source_color; // Will hold the sprite texture
uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
    vec4 tex_color = texture(tex_albedo, UV);
    ALBEDO = tex_color.rgb * tint_color.rgb;

}
