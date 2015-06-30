package com.rj.boulder.render;
import h2d.Tile;
import hxd.Res;

/**
 * ...
 * @author roguedjack
 */
class GameSprites {
	
	static public inline var SPRITE_SIZE:Int =  32;
	static public inline var ROWS:Int = 12;
	static public inline var COLUMNS:Int = 8;

	static public var Images:Array<Tile>;
	
	static public function init() {
		Images = Res.images.c64_sprites.toTile().grid(SPRITE_SIZE);
	}
	
	static public inline function at(x:Int, y:Int):Tile {
		return Images[y * COLUMNS + x];
	}
	
	/**
	 * 
	 * @param	ats x,y positions in sprite grid
	 * @return
	 */
	static public inline function makeFrames(ats:Array<Int>):Array<Tile> {
		var frames:Array<Tile> = [];
		var i:Int = 0;
		while (i < ats.length) {
			frames.push(at(ats[i], ats[i + 1]));
			i += 2;
		}
		return frames;
	}

	private function new() {}
}