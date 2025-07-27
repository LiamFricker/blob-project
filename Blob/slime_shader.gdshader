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

uniform int pulses = 0;
uniform vec2 pulseSource1 = vec2(0.0,0.0);
uniform float pulseAmp1: hint_range(0, 1);
uniform vec2 pulseSource2 = vec2(0.0,0.0);
uniform float pulseAmp2: hint_range(0, 1);
uniform vec2 pulseSource3 = vec2(0.0,0.0);
uniform float pulseAmp3: hint_range(0, 1);

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
			float distTemp = (halfLength-pow(dist,2)) / pow(halfLength, 2);
			VERTEX.x += 50.0 * (rippleSourceAmp.x) * distTemp;
			VERTEX.y += 50.0 * (rippleSourceAmp.y) * distTemp;
			UV.x += (rippleSourceAmp.x) * distTemp;
			UV.y += (rippleSourceAmp.y) * distTemp;
		}
		else if (dist <= halfLength){
			float distTemp = (halfLength-dist) / pow(halfLength, 2);
			VERTEX.x += 50.0 * (rippleSourceAmp.x) * distTemp;
			VERTEX.y += 50.0 * (rippleSourceAmp.y) * distTemp;
			UV.x += (rippleSourceAmp.x) * distTemp;
			UV.y += (rippleSourceAmp.y) * distTemp;
		}
		else{
			float distTemp = abs(halfLength-dist) / pow(halfLength, 3);
			VERTEX.x += 10.0 * (rippleSourceAmp.x) * distTemp;
			VERTEX.y += 10.0 * (rippleSourceAmp.y) * distTemp;
			UV.x += 0.2 * (rippleSourceAmp.x) * distTemp;
			UV.y += 0.2 * (rippleSourceAmp.y) * distTemp;
		}
		dist = distance(sign(rippleAmpMax)*rippleSource, centeredUV);
		float temp = abs(rippleAmp) - abs(rippleAmpMax)/5.0;

		float distDot = dot(rippleSource, vec2(-centeredUV.y, centeredUV.x));
		if (temp <= 0.0 && dist >= halfLength - 1.0 && dist <= halfLength + 1.0){
			float rippleAngle = atan(rippleSource.y, rippleSource.x);
			float distTemp = (1.0 - pow(halfLength-dist,2)) * pow(temp,2) / abs(rippleAmpMax);
			if (distDot >= PI/2.0 || distDot < -0.0){
				VERTEX.x += 250.0 * distTemp * cos(rippleAngle+PI/2.0);
				VERTEX.y += 250.0 * distTemp * sin(rippleAngle+PI/2.0);
				UV.x += 5.0 * distTemp * cos(rippleAngle+PI/2.0);
				UV.y += 5.0 * distTemp * sin(rippleAngle+PI/2.0);
			}
			else {
				VERTEX.x += 250.0 * distTemp * cos(rippleAngle-PI/2.0);
				VERTEX.y += 250.0 * distTemp * sin(rippleAngle-PI/2.0);
				UV.x += 5.0 * distTemp * cos(rippleAngle-PI/2.0);
				UV.y += 5.0 * distTemp * sin(rippleAngle-PI/2.0);
			}

		}
	}


	//Code the sides and code the bottom now okay?

	//VERTEX.x += 1.0 * pow(2.0*(1.0 - pow(distVect.y, 3)), 3);
	//VERTEX.y += 1.0 * pow(2.0*(1.0 - pow(distVect.x, 3)), 3);

	//Since we're adding pulses, it'll be better if we just used layered ifs
	if (pulses > 0){
		vec2 centeredUV = ((UV*2.0 / textureRectRatio)-vec2(1,1));
		vec2 diff = pulseSource1 - centeredUV;
		float distSquared = dot(diff, diff);
		float pulDist = 0.5 - abs(0.5 -pulseAmp1);//(distSquared > 2.0) ? 0.0 : 1.0 / pow(1.0+distSquared*(1.0-pulseAmp1)+ (2.0-distSquared)*pulseAmp1, 2);

		float pulAngle = atan(centeredUV.y - pulseSource1.y, centeredUV.x - pulseSource1.x);
		UV.x += 0.1 * pulDist * cos(pulAngle);
		UV.y += 0.1 * pulDist * sin(pulAngle);
		VERTEX.x += 5.0 * pulDist * cos(pulAngle);
		VERTEX.y += 5.0 * pulDist * sin(pulAngle);
		if (pulses > 1){
			diff = pulseSource2 - centeredUV;
			distSquared = dot(diff, diff);
			pulDist = 0.5 - abs(0.5 - pulseAmp2);

			pulAngle = atan(centeredUV.y - pulseSource2.y, centeredUV.x - pulseSource2.x);
			UV.x += 0.1 * pulDist * cos(pulAngle);
			UV.y += 0.1 * pulDist * sin(pulAngle);
			VERTEX.x += 5.0 * pulDist * cos(pulAngle);
			VERTEX.y += 5.0 * pulDist * sin(pulAngle);

			if (pulses > 2){
				diff = pulseSource3 - centeredUV;
				distSquared = dot(diff, diff);
				pulDist = (0.5 - abs(0.5 - pulseAmp3)) * (1.0 + 0.25 * float(pulses-3));

				pulAngle = atan(centeredUV.y - pulseSource3.y, centeredUV.x - pulseSource3.x);
				UV.x += 0.1 * pulDist * cos(pulAngle);
				UV.y += 0.1 * pulDist * sin(pulAngle);
				VERTEX.x += 5.0 * pulDist * cos(pulAngle);
				VERTEX.y += 5.0 * pulDist * sin(pulAngle);


			}
		}
	}

	//VERTEX.y += sin((UV.x - TIME * speed) * frequency) * amplitude * (0.5);
	//VERTEX.x += cos((UV.y - TIME * speed) * frequency) * amplitude * (1.0);
	//VERTEX.y += sin((UV.x - TIME * speed - PI/2.0) * frequency) * amplitude * (0.5);
	//VERTEX.x += cos((UV.y - TIME * speed - PI/2.0) * frequency) * amplitude * (1.0);

	//UV.y += sin((UV.x - TIME * speed) * frequency) * amplitude * (0.02);
	//UV.x += cos((UV.y - TIME * speed) * frequency) * amplitude * (0.02);
}

void fragment() {
	if (pulses > 0){
		COLOR = texture(TEXTURE, UV);

		vec2 centeredUV = ((UV*2.0 / textureRectRatio)-vec2(1,1));
		vec2 diff = centeredUV - pulseSource1;
		float distSquared = dot(diff, diff);
		//float pulDist = (distSquared > 200.0) ? 0.0 : 1.0 / pow(1.0+distSquared*(1.0-pulseAmp1)+ (2.0-distSquared)*pulseAmp1, 10);

		float pulseStrength = 0.5 - abs(0.5 - pulseAmp1);
		vec4 color = vec4(pulseStrength, pulseStrength, pulseStrength, 1);

	    float colorAmp = (sin(distSquared - pulseAmp1 * 2.25 + 2.0) - 0.95); //0.95

		color *= (colorAmp < 0.0) ? 0.0 : colorAmp;// - 0.01;
		//COLOR.a = 1.0 - distSquared;

	    COLOR += 2.0 * color;//mix(COLOR, color, 0.5);

		if (pulses > 1) {
			diff = centeredUV - pulseSource2;
			distSquared = dot(diff, diff);

			pulseStrength = 0.5 - abs(0.5 - pulseAmp2);
			color = vec4(pulseStrength, pulseStrength, pulseStrength, 1);

		    colorAmp = (sin(distSquared - pulseAmp2 * 2.25 + 2.0) - 0.95);

			color *= (colorAmp < 0.0) ? 0.0 : colorAmp;

		    COLOR += 2.0 * color;

			if (pulses > 2) {
				diff = centeredUV - pulseSource3;
				distSquared = dot(diff, diff);

				pulseStrength = 0.5 - abs(0.5 - pulseAmp3);
				color = vec4(pulseStrength, pulseStrength, pulseStrength, 1);

			    colorAmp = (sin(distSquared - pulseAmp3 * 2.25 + 2.0) - 0.95);

				color *= (colorAmp < 0.0) ? 0.0 : colorAmp;

			    COLOR += 2.0 * color;
			}
		}
	}

}
