shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform float pixel_size : hint_range(1.0, 12.0) = 1.0; // Reduced for high fidelity pixel art
uniform float color_levels : hint_range(2.0, 12.0) = 6.0;
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0; // Disabled by default for Metal Slug style
uniform float overlay_strength : hint_range(0.0, 1.0) = 0.58;
uniform float scanline_strength : hint_range(0.0, 0.35) = 0.1;
uniform float vignette_strength : hint_range(0.0, 0.45) = 0.12;
uniform vec4 tint_color : source_color = vec4(0.92, 0.94, 0.98, 1.0);


float bayer4(vec2 pos) {
    vec2 p = mod(floor(pos), 4.0);
    if (p.y < 1.0) {
        if (p.x < 1.0) return 0.0 / 16.0;
        if (p.x < 2.0) return 8.0 / 16.0;
        if (p.x < 3.0) return 2.0 / 16.0;
        return 10.0 / 16.0;
    }
    if (p.y < 2.0) {
        if (p.x < 1.0) return 12.0 / 16.0;
        if (p.x < 2.0) return 4.0 / 16.0;
        if (p.x < 3.0) return 14.0 / 16.0;
        return 6.0 / 16.0;
    }
    if (p.y < 3.0) {
        if (p.x < 1.0) return 3.0 / 16.0;
        if (p.x < 2.0) return 11.0 / 16.0;
        if (p.x < 3.0) return 1.0 / 16.0;
        return 9.0 / 16.0;
    }
    if (p.x < 1.0) return 15.0 / 16.0;
    if (p.x < 2.0) return 7.0 / 16.0;
    if (p.x < 3.0) return 13.0 / 16.0;
    return 5.0 / 16.0;
}


void fragment() {
    vec2 viewport_size = vec2(textureSize(screen_texture, 0));
    vec2 snapped_uv = floor(SCREEN_UV * viewport_size / pixel_size) * pixel_size / viewport_size;
    vec4 screen_col = texture(screen_texture, snapped_uv);
    vec4 overlay_col = texture(TEXTURE, UV);

    float levels = max(color_levels, 2.0);
    float dither = (bayer4(FRAGCOORD.xy) - 0.5) / levels;
    vec3 posterized = floor(clamp(screen_col.rgb + dither, 0.0, 1.0) * (levels - 1.0)) / (levels - 1.0);
    vec3 colorized = mix(screen_col.rgb, posterized, effect_strength);

    float scan = sin(FRAGCOORD.y * 3.14159265) * 0.5 + 0.5;
    vec2 centered = UV * 2.0 - 1.0;
    float vignette = smoothstep(0.2, 1.18, length(centered));

    colorized = mix(colorized, colorized * tint_color.rgb, 0.14);
    colorized = mix(colorized, clamp(colorized + overlay_col.rgb * tint_color.rgb * overlay_strength, 0.0, 1.0), clamp(overlay_col.a * 1.2, 0.0, 1.0));
    colorized *= 1.0 - scanline_strength * (1.0 - scan);
    colorized *= 1.0 - vignette_strength * vignette;

    COLOR = vec4(colorized, 1.0);
}
