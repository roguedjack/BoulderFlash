package com.rj.boulder.world;
import com.rj.heaps.Keys;
import hxd.Key;
import hxd.Res;

/**
 * Gameplay constants and settings.
 * 
 * @author roguedjack
 */
class Gameplay {	
	
	static public var KEYS_UP:Array<Int> = [Key.UP, Keys.Z, Keys.W];
	static public var KEYS_DOWN:Array<Int> = [Key.DOWN, Keys.S];
	static public var KEYS_LEFT:Array<Int> = [Key.LEFT, Keys.Q, Key.A];
	static public var KEYS_RIGHT:Array<Int> = [Key.RIGHT, Keys.D];
	static public var KEYS_ACTION:Array<Int> = [Key.SPACE];	
	static public var KEYS_SUICIDE:Array<Int> = [Key.ESCAPE];
	
	static public inline var LEVEL_TICKS_PER_SECOND = 6.0;
	
	static public inline var PLAYER_TICKS_PER_SECOND	= 1.25 * LEVEL_TICKS_PER_SECOND;
	static public inline var PLAYER_SPAWN_WAIT_DELAY 	= 20 / LEVEL_TICKS_PER_SECOND;
	
	static public inline var PLAYER_ANIM_SPEED 			= 25.0;
	static public inline var MONSTER_ANIM_SPEED 		= 15.0;
	static public inline var DIAMOND_ANIM_SPEED 		= 15.0;
	static public inline var AMOEBA_ANIM_SPEED 			= 15.0;
	static public inline var MAGICWALL_ANIM_SPEED 		= 15.0;	
	static public inline var EXPLOSION_ANIM_SPEED 		= LEVEL_TICKS_PER_SECOND;
	static public inline var EXIT_ANIM_SPEED 			= 2.0;
	
	static public inline var AMOEBA_GROWTH_TICKS_MIN_COOLDOWN 	= 15;	
	static public inline var AMOEBA_GROWTH_TICKS_MAX_COOLDOWN 	= 30;	
	static public inline var AMOEBA_TOO_BIG_COUNT				= 200;
	
	static public inline var MAGICWALL_ACTIVE_TICKS = 20 * LEVEL_TICKS_PER_SECOND;
	
	static public inline var VIEW_SCROLL_XFOCUS:Int 	= 10;
	static public inline var VIEW_SCROLL_YFOCUS:Int 	= 7;
	static public inline var VIEW_SCROLL_STEP:Float 	= 0.20;
	
	static public inline var LEVEL_WIN_FLASH_DURATION:Float = 1;
	static public inline var LEVEL_WIN_FLASH_COLOR:Int 		= 0xFFFFFF;
	static public inline var LEVEL_WIN_FLASH_PERIOD:Float 	= 5.0 / 60.0;
	
	static public var MAP_CYCLE = [ ];
	static public var CURRENT_MAP = 0;
	
	static public function newGame() {
		CURRENT_MAP = 0;
		MAP_CYCLE = [ 
			Res.levels.s1l1, Res.levels.s2l1, Res.levels.s3l1, Res.levels.s4l1, Res.levels.s5l1,
			Res.levels.s6l1, Res.levels.s7l1, Res.levels.s8l1, Res.levels.s9l1, Res.levels.s10l1,
			Res.levels.s11l1, Res.levels.s12l1
		];
	}
	
	
	private function new() { }	
}