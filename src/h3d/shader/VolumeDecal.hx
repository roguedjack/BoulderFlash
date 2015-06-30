package h3d.shader;

class VolumeDecal extends hxsl.Shader {

	static var SRC = {

		@:import BaseMesh;

		@global var depthMap : Sampler2D;

		@param var scale : Vec2;
		@param var normal : Vec3;
		var calculatedUV : Vec2;

		function vertex() {
			transformedNormal = normal;
		}

		function fragment() {
			var matrix = camera.inverseViewProj * global.modelViewInverse;
			var screenPos = projectedPosition.xy / projectedPosition.w;
			var tuv = screenPos * vec2(0.5, -0.5) + vec2(0.5, 0.5);
			var ruv = vec4(
				screenPos,
				unpack(depthMap.get(tuv)),
				1
			);
			var wpos = ruv * matrix;
			var ppos = ruv * camera.inverseViewProj;
			pixelTransformedPosition = ppos.xyz / ppos.w;
			calculatedUV = scale * (wpos.xy / wpos.w) + 0.5;
			if( min(min(calculatedUV.x, calculatedUV.y), min(1 - calculatedUV.x, 1 - calculatedUV.y)) < 0 ) discard;
		}

	};

	public function new() {
		super();
		normal.set(0, 0, 1);
		scale.set(1, 1);
	}

}