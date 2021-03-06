package hxd;

typedef BitmapInnerData =
#if (flash || openfl || nme)
	flash.display.BitmapData;
#elseif js
	js.html.CanvasRenderingContext2D;
#else
	BitmapInnerDataImpl;

class BitmapInnerDataImpl {
	public var pixels : haxe.ds.Vector<Int>;
	public var width : Int;
	public var height : Int;
	public function new() {
	}
}
#end

class BitmapData {

	#if (flash || nme || openfl)
	static var tmpRect = new flash.geom.Rectangle();
	static var tmpPoint = new flash.geom.Point();
	static var tmpMatrix = new flash.geom.Matrix();
	#end

#if (flash||openfl||nme)
	var bmp : flash.display.BitmapData;
#elseif js
	var ctx : js.html.CanvasRenderingContext2D;
	var lockImage : js.html.ImageData;
	var pixel : js.html.ImageData;
#else
	var data : BitmapInnerData;
#end

	public var width(get, never) : Int;
	public var height(get, never) : Int;

	public function new(width:Int, height:Int) {
		if( width == -101 && height == -102 ) {
			// no alloc
		} else {
			#if (flash||openfl||nme)
			bmp = new flash.display.BitmapData(width, height, true, 0);
			#elseif js
			var canvas = js.Browser.document.createCanvasElement();
			canvas.width = width;
			canvas.height = height;
			ctx = canvas.getContext2d();
			#else
			data = new BitmapInnerData();
			data.pixels = new haxe.ds.Vector(width * height);
			data.width = width;
			data.height = height;
			#end
		}
	}

	public function clear( color : Int ) {
		#if (flash||openfl||nme)
		bmp.fillRect(bmp.rect, color);
		#else
		fill(0, 0, width, height, color);
		#end
	}

	static inline function notImplemented() {
		throw "Not implemented";
	}

	public function fill( x : Int, y : Int, width : Int, height : Int, color : Int ) {
		#if (flash || openfl || nme)
		var r = tmpRect;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		bmp.fillRect(r, color);
		#elseif js
		ctx.fillStyle = 'rgba(${(color>>16)&0xFF}, ${(color>>8)&0xFF}, ${color&0xFF}, ${(color>>>24)/255})';
		ctx.fillRect(x, y, width, height);
		#else
		if( x < 0 ) {
			width += x;
			x = 0;
		}
		if( y < 0 ) {
			height += y;
			y = 0;
		}
		if( x + width > data.width )
			width = data.width - x;
		if( y + height > data.height )
			height = data.height - y;
		for( dy in 0...height ) {
			var p = x + (y + dy) * data.width;
			for( dx in 0...width )
				data.pixels[p++] = color;
		}
		#end
	}

	public function draw( x : Int, y : Int, src : BitmapData, srcX : Int, srcY : Int, width : Int, height : Int, ?blendMode : h2d.BlendMode ) {
		#if (flash || openfl || nme)
		if( blendMode == null ) blendMode = Alpha;
		var r = tmpRect;
		r.x = srcX;
		r.y = srcY;
		r.width = width;
		r.height = height;
		switch( blendMode ) {
		case None:
			var p = tmpPoint;
			p.x = x;
			p.y = y;
			bmp.copyPixels(src.bmp, r, p);
		case Alpha:
			var p = tmpPoint;
			p.x = x;
			p.y = y;
			bmp.copyPixels(src.bmp, r, p, src.bmp, null, true);
		case Add:
			var m = tmpMatrix;
			m.tx = x - srcX;
			m.ty = y - srcY;
			r.x = x;
			r.y = y;
			bmp.draw(src.bmp, m, null, flash.display.BlendMode.ADD, r, false);
		case Erase:
			var m = tmpMatrix;
			m.tx = x - srcX;
			m.ty = y - srcY;
			r.x = x;
			r.y = y;
			bmp.draw(src.bmp, m, null, flash.display.BlendMode.ERASE, r, false);
		case Multiply:
			var m = tmpMatrix;
			m.tx = x - srcX;
			m.ty = y - srcY;
			r.x = x;
			r.y = y;
			bmp.draw(src.bmp, m, null, flash.display.BlendMode.MULTIPLY, r, false);
		case Screen:
			var m = tmpMatrix;
			m.tx = x - srcX;
			m.ty = y - srcY;
			r.x = x;
			r.y = y;
			bmp.draw(src.bmp, m, null, flash.display.BlendMode.SCREEN, r, false);
		case SoftAdd:
			throw "BlendMode not supported";
		}
		#else
		notImplemented();
		#end
	}

	public function drawScaled( x : Int, y : Int, width : Int, height : Int, src : BitmapData, srcX : Int, srcY : Int, srcWidth : Int, srcHeight : Int, ?blendMode : h2d.BlendMode, smooth = true ) {
		if( blendMode == null ) blendMode = Alpha;
		#if (flash || openfl || nme)

		var b = switch( blendMode ) {
		case None:
			// todo : clear before ?
			flash.display.BlendMode.NORMAL;
		case Alpha:
			flash.display.BlendMode.NORMAL;
		case Add:
			flash.display.BlendMode.ADD;
		case Erase:
			flash.display.BlendMode.ERASE;
		case Multiply:
			flash.display.BlendMode.MULTIPLY;
		case Screen:
			flash.display.BlendMode.SCREEN;
		case SoftAdd:
			throw "BlendMode not supported";
		}

		var m = tmpMatrix;
		m.a = width / srcWidth;
		m.d = height / srcHeight;
		m.tx = x - srcX * m.a;
		m.ty = y - srcY * m.d;

		var r = tmpRect;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;

		bmp.draw(src.bmp, m, null, b, r, smooth);
		m.a = 1;
		m.d = 1;

		#else
		notImplemented();
		#end
	}

	public function line( x0 : Int, y0 : Int, x1 : Int, y1 : Int, color : Int ) {
		var dx = x1 - x0;
		var dy = y1 - y0;
		if( dx == 0 ) {
			if( y1 < y0 ) {
				var tmp = y0;
				y0 = y1;
				y1 = tmp;
			}
			for( y in y0...y1 + 1 )
				setPixel(x0, y, color);
		} else if( dy == 0 ) {
			if( x1 < x0 ) {
				var tmp = x0;
				x0 = x1;
				x1 = tmp;
			}
			for( x in x0...x1 + 1 )
				setPixel(x, y0, color);
		} else {
			throw "TODO : brensenham line";
		}
	}

	public inline function dispose() {
		#if (flash||openfl||nme)
		bmp.dispose();
		#elseif js
		ctx = null;
		pixel = null;
		#else
		data = null;
		#end
	}

	public function clone() {
		return sub(0,0,width,height);
	}

	public function sub( x, y, w, h ) : BitmapData {
		#if (flash || openfl || nme)
		var b = new flash.display.BitmapData(w, h);
		b.copyPixels(bmp, new flash.geom.Rectangle(x, y, w, h), new flash.geom.Point(0, 0));
		return fromNative(b);
		#else
		notImplemented();
		return null;
		#end
	}

	/**
		Inform that we will perform several pixel operations on the BitmapData.
	**/
	public function lock() {
		#if flash
		bmp.lock();
		#elseif js
		if( lockImage == null )
			lockImage = ctx.getImageData(0, 0, width, height);
		#end
	}

	/**
		Inform that we have finished performing pixel operations on the BitmapData.
	**/
	public function unlock() {
		#if flash
		bmp.unlock();
		#elseif js
		if( lockImage != null ) {
			ctx.putImageData(lockImage, 0, 0);
			lockImage = null;
		}
		#end
	}

	/**
		Access the pixel color value at the given position. Note : this function can be very slow if done many times and the BitmapData has not been locked.
	**/
	public #if (flash || openfl || nme) inline #end function getPixel( x : Int, y : Int ) : Int {
		#if ( flash || openfl || nme )
		return bmp.getPixel32(x, y);
		#elseif js
		var i = lockImage;
		var a;
		if( i != null )
			a = (x + y * i.width) << 2;
		else {
			a = 0;
			i = ctx.getImageData(x, y, 1, 1);
		}
		return (i.data[a] << 16) | (i.data[a|1] << 8) | i.data[a|2] | (i.data[a|3] << 24);
		#else
		return if( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.pixels[x + y * data.width] else 0;
		#end
	}

	/**
		Modify the pixel color value at the given position. Note : this function can be very slow if done many times and the BitmapData has not been locked.
	**/
	public #if (flash || openfl || nme) inline #end function setPixel( x : Int, y : Int, c : Int ) {
		#if ( flash || openfl || nme)
		bmp.setPixel32(x, y, c);
		#elseif js
		var i : js.html.ImageData = lockImage;
		if( i != null ) {
			var a = (x + y * i.width) << 2;
			i.data[a] = (c >> 16) & 0xFF;
			i.data[a|1] = (c >> 8) & 0xFF;
			i.data[a|2] = c & 0xFF;
			i.data[a|3] = (c >>> 24) & 0xFF;
			return;
		}
		var i = pixel;
		if( i == null ) {
			i = ctx.createImageData(1, 1);
			pixel = i;
		}
		i.data[0] = (c >> 16) & 0xFF;
		i.data[1] = (c >> 8) & 0xFF;
		i.data[2] = c & 0xFF;
		i.data[3] = (c >>> 24) & 0xFF;
		ctx.putImageData(i, x, y);
		#else
		if( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.pixels[x + y * data.width] = c;
		#end
	}

	inline function get_width() : Int {
		#if (flash || nme || openfl)
		return bmp.width;
		#elseif js
		return ctx.canvas.width;
		#else
		return data.width;
		#end
	}

	inline function get_height() {
		#if (flash || nme || openfl)
		return bmp.height;
		#elseif js
		return ctx.canvas.height;
		#else
		return data.height;
		#end
	}

	public function getPixels() : Pixels {
		#if (flash || nme || openfl)
		var p = new Pixels(width, height, haxe.io.Bytes.ofData(bmp.getPixels(bmp.rect)), ARGB);
		p.flags.set(AlphaPremultiplied);
		return p;
		#elseif js
		var w = width;
		var h = height;
		var data = ctx.getImageData(0, 0, w, h).data;
			#if (haxe_ver < 3.2)
			var pixels = [];
			for( i in 0...w * h * 4 )
				pixels.push(data[i]);
			#else
			// starting from Haxe 3.2, bytes are based on native array
			var pixels = data.buffer;
			#end
		return new Pixels(w, h, haxe.io.Bytes.ofData(pixels), RGBA);
		#else
		var out = hxd.impl.Tmp.getBytes(data.width * data.height * 4);
		for( i in 0...data.width*data.height )
			out.setInt32(i << 2, data.pixels[i]);
		return new Pixels(data.width, data.height, out, BGRA);
		#end
	}

	public function setPixels( pixels : Pixels ) {
		if( pixels.width != width || pixels.height != height )
			throw "Invalid pixels size";
		pixels.setFlip(false);
		#if flash
		var bytes = pixels.bytes.getData();
		bytes.position = 0;
		switch( pixels.format ) {
		case BGRA:
			bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
		case ARGB:
			bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		case RGBA:
			pixels.convert(BGRA);
			bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
		}
		bmp.setPixels(bmp.rect, bytes);
		#elseif js
		var img = ctx.createImageData(pixels.width, pixels.height);
		pixels.convert(RGBA);
		for( i in 0...pixels.width*pixels.height*4 ) img.data[i] = pixels.bytes.get(i);
		ctx.putImageData(img, 0, 0);
		#elseif (nme || openfl)
		pixels.convert(BGRA);
		bmp.setPixels(bmp.rect, flash.utils.ByteArray.fromBytes(pixels.bytes));
		#else
		pixels.convert(BGRA);
		var src = pixels.bytes;
		for( i in 0...width * height )
			data.pixels[i] = src.getInt32(i<<2);
		#end
	}

	public inline function toNative() : BitmapInnerData {
		#if (flash || nme || openfl)
		return bmp;
		#elseif js
		return ctx;
		#else
		return data;
		#end
	}

	public static function fromNative( data : BitmapInnerData ) : BitmapData {
		var b = new BitmapData( -101, -102 );
		#if (flash || nme || openfl)
		b.bmp = data;
		#elseif js
		b.ctx = data;
		#else
		b.data = data;
		#end
		return b;
	}

	public function toPNG() {
		var pixels = getPixels();
		var png = pixels.toPNG();
		pixels.dispose();
		return png;
	}

}