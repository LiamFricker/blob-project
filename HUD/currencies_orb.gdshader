shader_type canvas_item;

uniform float offset = 0.0;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

float superSin (float f) {
	return 0.2 + 0.8 * sin(.1*f) * sin(.8*f); 
}

void fragment() {
	//float temp = (1-UV.y);
	//float pct = TIME + offset;
	
    float pct = TIME + offset; //* TIME;
	
	vec4 result = vec4(superSin(pct), superSin(pct+3.0), superSin(pct+6.0), COLOR.a);
	COLOR = mix(COLOR, result, 0.4);
}
