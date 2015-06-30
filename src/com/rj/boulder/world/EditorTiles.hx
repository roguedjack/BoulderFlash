package com.rj.boulder.world;

/**
 * Tiled editor tile values.<br>
 * Must match the tileset indices.
 * 
 * @author roguedjack
 */
class EditorTiles {	
	static public inline var NULL		= 0;
	static public inline var EMPTY 		= 1 + 6 * 8 + 0;	// (0,6)
	static public inline var EARTH 		= 1 + 7 * 8 + 1;	// (1,7)
	static public inline var WALL 		= 1 + 6 * 8 + 3; 	// (3,6)
	static public inline var BARRIER 	= 1 + 6 * 8 + 1;	// (1,6)

	static public inline var PLAYER_START 	= 1 + 0 * 8 + 0; // (0,0)
	static public inline var PLAYER_EXIT 	= 1 + 6 * 8 + 2; // (2,6)
	
	static public inline var ENT_BOULDER	= 1 + 7 * 8 + 0;	// (0,7)
	static public inline var ENT_DIAMOND 	= 1 + 10 * 8 + 0;	// (0,10)
	static public inline var ENT_FIREFLY 	= 1 + 9 * 8 + 0;	// (0,9)
	static public inline var ENT_BUTTERFLY	= 1 + 11 * 8 + 0;	// (0,11)
	static public inline var ENT_AMOEBA		= 1 + 8 * 8 + 0;	// (0,8)
	static public inline var ENT_MAGICWALL  = 1 + 6 * 8 + 4;	// (4,6)
	
	private function new() { }
}