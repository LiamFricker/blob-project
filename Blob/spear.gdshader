shader_type canvas_item;

uniform float progress: hint_range(0, 1);
uniform vec3 startColor: source_color = vec3(1.0,1.0,0.0);
uniform vec3 endColor: source_color = vec3(0.0,1.0,0.0);



void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//float temp = max(2.0*fract(TIME), 0.5)+1.00*(-1.0+UV.y)+2.0*fract(TIME);
	float temp = max(2.0*progress, 0.5)+1.00*(-1.0+UV.y)+2.0*progress;
	float pct = 0.15*sin(3.0*PI*UV.x) + temp-0.65;
	vec3 progressColor = mix(startColor, endColor, 0.35*sin(3.0*PI*UV.x + 3.0*PI) + temp -0.85);
	COLOR = vec4(progressColor, pct);
}
