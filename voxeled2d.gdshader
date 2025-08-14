shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform float thickness = 0.1;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    if (tex.a < 0.1) discard;
    ALBEDO = tex.rgb;
}

void vertex() {
    VERTEX.z += thickness * (UV.y - 0.5); // desloca vértices para dar "volume"
}
