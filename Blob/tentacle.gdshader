shader_type canvas_item;

//Normal Variables
uniform float speed = 2.0;
uniform float frequency = 2.5;
uniform float amplitude = 0.0;

uniform float tentLength = 8.0;

//Spin Variables
uniform float direction = 0.0;

//Whip Variables
uniform float whip_direction: hint_range(-1.0, 1.0);
uniform bool reverse_direction = false;


void vertex() {
	//Basic Wave
	VERTEX.y += sin((VERTEX.x - TIME * speed) * frequency) * amplitude * (1.0);
	if (direction != 0.0){
		VERTEX.y += (abs(direction) <= 1.0) ? tentLength*6.0*direction * pow(VERTEX.x/(tentLength*8.0), 2): tentLength*6.0*sign(direction) * pow(VERTEX.x/(tentLength*8.0), 2);

		VERTEX.x -= tentLength*2.0*abs(direction) * pow(VERTEX.x/(tentLength*8.0), 2);
	}
	if (whip_direction != 0.0){
		if (reverse_direction){
			VERTEX.y += tentLength*5.0*whip_direction * pow(VERTEX.x/(tentLength*8.0), 2);
			VERTEX.x -= tentLength*2.0*abs(whip_direction) * pow(VERTEX.x/(tentLength*8.0), 2);
		}
		else {
			VERTEX.y += tentLength*8.0*whip_direction* VERTEX.x/(tentLength*8.0);
			VERTEX.x -= tentLength*8.0*abs(whip_direction) * pow(VERTEX.x/(tentLength*8.0), 4);
		}
	}
	//VERTEX.y += tentLength*6.0 * pow(VERTEX.x/(tentLength*8.0), 2);
	//VERTEX.x -= tentLength*2.0 * pow(VERTEX.x/(tentLength*8.0), 2);
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
