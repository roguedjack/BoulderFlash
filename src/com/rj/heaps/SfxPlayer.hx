package com.rj.heaps;
import haxe.Timer;
import hxd.res.Sound;

/**
 * 
 * @author roguedjack
 */
@:final
class SfxPlayer {
	
	static private var _frameTime:Float;
	static private var _playedThisFrame:Array<Sound>;
	
	static public function tick(elapsed:Float) {
		_frameTime = Timer.stamp();
		_playedThisFrame = [];
	}

	/**
	 * Plays the sfx if not already playing this frame.
	 * 
	 * @param	sfx
	 * @param	vol
	 */
	static public function play(sfx:Sound, vol:Float = 0.5) {
		if (vol <= 0) {
			return;
		}				
		if (_playedThisFrame.indexOf(sfx) != -1) {
			return;
		}
		_playedThisFrame.push(sfx);
		sfx.play(false, vol);
	}

	private function new() {}
	
}