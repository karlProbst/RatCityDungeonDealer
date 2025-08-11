shader_type spatial;
render_mode unshaded;

uniform sampler2D u_viewport_tex;

void fragment() {
    vec3 col = texture(u_viewport_tex, UV).rgb;
    ALBEDO = col;
}
