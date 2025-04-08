shader_type canvas_item;

uniform float speed = 2.0;
//uniform float frequency_y = 5.0;
uniform float frequency = 2.5;
//uniform float amplitude_y = 50.0;
//uniform float amplitude = 25.0;
uniform float amplitude = 0.5;
uniform float textureRectRatio = 1.0; //Slime is 32 by 32. Set this to dim of Slime / dim of Texture.
//uniform float inclination = 50.0;

//(0.707+1.0)/2.0,(0.707+1.0)/2.0 do this on player side
//uniform vec2 rippleSource = vec2(0.854,0.854);
uniform vec2 rippleSource = vec2(0.0,-1.0);
uniform float rippleAmp: hint_range(-2.5, 2.5);
uniform float rippleAmpMax = 2.5;
uniform bool rippleOn = false;

//I ain't got time to do this right now
//You should try removing the UV's at the end
//I'm pretty sure the UVs are the ones that are causing it to go in a certain direction.
//You might be able to do something with cos/sin to make a circle around the slime or make it centered around center
//(use abs since <0 = 0)
//But like the UVs are causing the oscilation to equal 0 at 0.

//Frequency makes it jiggle more violently
//Speed makes it jiggle faster

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
	/*
	VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * UV.y;
	VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * UV.x;
	VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * UV.x;
	VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * UV.y;

	VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * (1.0 - UV.y);
	VERTEX.y += sin((UV.x - TIME * speed - PI/2.0) * frequency) * amplitude * (UV.y + 0.5);
	VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * UV.x * random(UV);
	VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * (1.0 -UV.x);
	VERTEX.x += cos((UV.y - TIME * speed - PI/2.0) * frequency) * amplitude * (UV.x + 0.5);
	VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * UV.y * random(UV);
	*/

	//float rand = pow(random(UV), 0.25);
	if (rippleOn) {
		vec2 centeredUV = ((UV*2.0 / textureRectRatio)-vec2(1,1));
		vec2 rippleSourceAmp = rippleSource * rippleAmp;
		vec2 distVect = rippleSource - centeredUV;
		float dist;
		if (rippleAmp < 0.0) {
			//distVect = -1.0*rippleSource - centeredUV;
			dist = distance(-1.0*rippleSource, centeredUV);
		}
		else{
			//distVect = rippleSource - centeredUV;
			dist = distance(rippleSource, centeredUV);
		}
		float halfLength = length(rippleSource) * sqrt(2.0);

		if (dist <= 1.0){
			VERTEX.x += 50.0 / pow(halfLength, 2)  * (rippleSourceAmp.x) * (halfLength-pow(dist,2));
			VERTEX.y += 50.0 / pow(halfLength, 2) * (rippleSourceAmp.y) * (halfLength-pow(dist,2));
		}
		else if (dist <= halfLength){
			VERTEX.x += 50.0 / pow(halfLength, 2)* (rippleSourceAmp.x) * (halfLength-dist);
			VERTEX.y += 50.0 / pow(halfLength, 2)* (rippleSourceAmp.y) * (halfLength-dist);
		}
		else{
			VERTEX.x += 10.0 / pow(halfLength, 3)* (rippleSourceAmp.x) * abs(dist-halfLength);
			VERTEX.y += 10.0 / pow(halfLength, 3)* (rippleSourceAmp.y) * abs(dist-halfLength);
		}
		dist = distance(sign(rippleAmpMax)*rippleSource, centeredUV);
		float temp = abs(rippleAmp) - abs(rippleAmpMax)/5.0;
		if (temp <= 0.0 && dist >= halfLength - 1.0 && dist <= halfLength + 1.0){
			float rippleAngle = atan(rippleSource.y, rippleSource.x);
			if (atan(distVect.y, distVect.x) >= PI/2.0 || atan(distVect.y, distVect.x) < -PI/1.3){
				VERTEX.x += 250.0/abs(rippleAmpMax) * cos(rippleAngle+PI/2.0) * (1.0 - pow(halfLength-dist,2)) * pow(temp,2);
				VERTEX.y += 250.0/abs(rippleAmpMax) * sin(rippleAngle+PI/2.0) * (1.0 - pow(halfLength-dist,2)) * pow(temp,2);
			}
			else {
				VERTEX.x += 250.0/abs(rippleAmpMax) * cos(rippleAngle-PI/2.0) * (1.0 - pow(halfLength-dist,2)) * pow(temp,2);
				VERTEX.y += 250.0/abs(rippleAmpMax) * sin(rippleAngle-PI/2.0) * (1.0 - pow(halfLength-dist,2)) * pow(temp,2);
			}

		}
	}


	//Code the sides and code the bottom now okay?

	//VERTEX.x += 1.0 * pow(2.0*(1.0 - pow(distVect.y, 3)), 3);
	//VERTEX.y += 1.0 * pow(2.0*(1.0 - pow(distVect.x, 3)), 3);

	VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * (0.5);
	VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * (1.0);
	VERTEX.y += sin((UV.x - TIME * speed - PI/2.0) * frequency) * amplitude * (0.5);
	VERTEX.x += cos((UV.y - TIME * speed - PI/2.0) * frequency) * amplitude * (1.0);


}