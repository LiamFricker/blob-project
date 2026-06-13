shader_type canvas_item;

uniform float size: hint_range(0, 50) = 5.0;
uniform float border_size: hint_range(0, 1) = 0.04;
uniform float speed: hint_range(0, 2) = 0.25;

vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 augmentedUV = UV;
	augmentedUV.x *= 1.25;
	float angle = PI/4.0;
    augmentedUV = mat2(vec2(cos(angle),-sin(angle)), vec2(sin(angle),cos(angle))) * augmentedUV;

	//Get the border
	vec2 border = fract(augmentedUV * size);
	float glare_x = border.x;
	border = step(2.0*border_size, border);
	float border_norm = border.x * border.y;

	//Get the colors for each panel
    vec2 panel_colors = ceil(augmentedUV * size);
	//This needs to happen or else some panels will never go off (FIGURE OUT WHY)
	panel_colors *= panel_colors;
	panel_colors = random(panel_colors);
    float colors_norm = fract(panel_colors.x * panel_colors.y * TIME * speed);

    //This is messy but I like how it looks better than a sin function
	//The bug here is that I got the step function logic off, but it sorta looks better flashing in and out imo
	//Nvm this looks better now
	float stepwise = step(0.5, colors_norm);
    //float temp = (1.0 - stepwise) * 3.67 * abs(colors_norm - 0.3) - 0.6;
    //colors_norm = temp + stepwise * -1.5 * abs(colors_norm - 0.8) + 0.8;
	float temp = (1.0 - stepwise) * 1.0 * sin(colors_norm*4.0*PI);
	colors_norm = temp + stepwise * -0.8 * sin(colors_norm*2.0*PI);
	colors_norm *= border_norm;
	float glare = (glare_x)*(0.5*sin(TIME)+0.5);
	glare += (1.0-glare_x)*(0.25*sin(TIME+PI)+0.25);
	glare *= colors_norm;
    COLOR = vec4(colors_norm+glare,colors_norm,0.0,colors_norm);

}
