shader_type canvas_item;

uniform vec3 start_color : source_color;
uniform vec3 end_color : source_color;

void fragment() {
	float circ = length(UV);//sqrt(uvx_squard + uvy_squard);
	vec2 normUV = normalize(UV);
	float offset = 0.4*sin(10.0*atan(UV.x, normUV.x))+0.6;
	float firstpart = 1.0 * circ - 1.0 * floor(2.0*circ);// - 0.5 * floor(1.0*circ);
	float pct = firstpart + 1.75*offset/(1.0+circ);//min(, 0.5);

	float sinstuff = abs(sin(8.0*atan(UV.y, UV.x)));
	offset = 10.0*(sinstuff);//+0.6;
	float secondpart = 1.0 * floor((offset) * 0.5*(1.5 - circ)) - 0.5*circ;
	secondpart *= 1.0 * step(2.0-circ, 1.0);

	pct = max(pct, 0.0) + secondpart;
	vec3 gradient = mix(start_color, end_color, 2.0 + 1.5*sin(UV.y + UV.x + 2.0*TIME));
	COLOR = vec4(gradient, pct);

}
