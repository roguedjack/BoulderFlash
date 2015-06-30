package h3d.pass;

class ColorMatrixShader extends h3d.shader.ScreenShader {

	static var SRC = {

		@param var texture : Sampler2D;
		@param var matrix : Mat4;

		@const var useMask : Bool;
		@const var maskInvert : Bool;
		@const var hasSecondMatrix : Bool;
		@param var matrix2 : Mat4;
		@param var mask : Sampler2D;
		@param var maskMatA : Vec3;
		@param var maskMatB : Vec3;
		@param var maskPower : Float;
		@param var maskChannel : Vec4;

		function fragment() {
			if( useMask ) {
				var color = texture.get(input.uv);
				var uv = vec3(input.uv, 1);
				var k = pow(mask.get( vec2(uv.dot(maskMatA), uv.dot(maskMatB)) ).dot(maskChannel), maskPower);
				var color2 = hasSecondMatrix ? color * matrix2 : color;
				output.color = maskInvert ? mix(color2, color * matrix, k) : mix(color * matrix, color2, k);
			} else
				output.color = texture.get(input.uv) * matrix;
		}

	};

}

class ColorMatrix extends ScreenFx<ColorMatrixShader> {

	public var matrix(get, set) : h3d.Matrix;
	public var maskPower(get, set) : Float;

	public function new( ?m : h3d.Matrix ) {
		super(new ColorMatrixShader());
		if( m != null ) shader.matrix = m;
		shader.maskPower = 1;
		shader.maskChannel.set(1, 0, 0, 0); // red channel
	}

	inline function get_matrix() return shader.matrix;
	inline function set_matrix(m) return shader.matrix = m;
	inline function get_maskPower() return shader.maskPower;
	inline function set_maskPower(p) return shader.maskPower = p;

	public function apply( src : h3d.mat.Texture, out : h3d.mat.Texture, ?mask : h3d.mat.Texture, ?maskMatrix : h2d.col.Matrix ) {
		var old = engine.setTarget(out);
		shader.texture = src;
		shader.useMask = mask != null;
		if( mask != null ) {
			shader.mask = mask;
			if( maskMatrix == null ) {
				shader.maskMatA.set(1, 0, 0);
				shader.maskMatB.set(0, 1, 0);
			} else {
				shader.maskMatA.set(maskMatrix.a, maskMatrix.c, maskMatrix.x);
				shader.maskMatB.set(maskMatrix.b, maskMatrix.d, maskMatrix.y);
			}
		}
		render();
		engine.setTarget(old);
	}

}