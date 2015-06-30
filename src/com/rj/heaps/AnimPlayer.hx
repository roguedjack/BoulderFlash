package com.rj.heaps;
import h2d.Anim;

/**
 * 
 * @author roguedjack
 */
class AnimPlayer {
	
	private var _targetAnim:Anim;	
	private var _anims:Map<String, Anim>;
	public var currentAnim(default,null):String;
	
	public function new(targetAnim:Anim) {
		_targetAnim = targetAnim;
		_anims = new Map<String, Anim>();		
		currentAnim = "";
	}
		
	public function defAnim(name:String, anim:Anim, isLooping:Bool=false) {
		_anims.set(name, anim);
	}
	
	public function getAnim(name:String):Anim {
		return _anims.get(name);
	}
	
	/**
	 * Starts or continues an animation.
	 * @param	name
	 * @param	forceRestart
	 */
	public function playAnim(name:String, forceRestart:Bool = false) {
		if (currentAnim == name && !forceRestart) {
			return;
		}		
		var a:Anim = _anims.get(name);
		if (a == null) {
			throw "undefined animation " + name;
		}
		_targetAnim.frames = a.frames;
		_targetAnim.speed = a.speed;
		_targetAnim.play(a.frames, 0);
		currentAnim = name;
	}	
}