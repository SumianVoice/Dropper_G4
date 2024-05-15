shader_type spatial;

uniform sampler2D ng_lava_mask;
uniform sampler2D ng_lava_mask2;
uniform sampler2D ng_lava;
uniform sampler2D ng_stone;
uniform float uv_scale = 1;
uniform float scroll = 0.01;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float nv_lava_mask = texture(ng_lava_mask, UV * uv_scale + TIME * scroll * vec2(0.1,0.2)).r;
	float nv_lava_mask2 = texture(ng_lava_mask2, UV * uv_scale + TIME * scroll * vec2(0.4,0.5)).r;
	nv_lava_mask = nv_lava_mask * nv_lava_mask2;
	vec3 nv_lava  = texture(ng_lava, UV * uv_scale + TIME * scroll * vec2(1,0.7)).rgb;
	vec3 nv_lava2  = texture(ng_lava, UV * uv_scale + TIME * scroll * vec2(0.9,0.8)).rgb;
	nv_lava = (nv_lava + nv_lava2) / 2.0;
	vec3 nv_stone  = texture(ng_stone, UV * uv_scale + TIME * scroll * vec2(1,0.7)).rgb;
	ALBEDO = mix(nv_lava, nv_stone, nv_lava_mask);
	EMISSION = ALBEDO;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
