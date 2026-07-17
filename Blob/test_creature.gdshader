shader_type canvas_item;

uniform vec4 end_color: source_color = vec4(0, 0.545, 1, 1);
uniform float progress: hint_range(0.0, 1.0) = 0.0;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {

	//For Sprite Group 
	//vec4 tex = texture(screen_texture,SCREEN_UV);
	
	vec4 tex = texture(TEXTURE, UV);
	vec3 result_color = mix(tex.rgb, end_color.rgb, progress);
	COLOR = vec4(result_color, tex.a);
}