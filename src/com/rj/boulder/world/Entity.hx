package com.rj.boulder.world;
import com.rj.boulder.render.GameSprites;
import com.rj.boulder.world.entities.Explosion;
import com.rj.heaps.AnimPlayer;
import com.rj.heaps.SfxPlayer;
import h2d.Anim;
import h2d.Tile;
import haxe.Timer;
import hxd.res.Sound;
import hxd.snd.Channel;

/**
 * An actor in a level.<br>
 * Entities are ticked at regular interval by the level owning them, so they all move at the same speed.
 * The only exception is the player which is handled separatly.
 * 
 * @author roguedjack
 */
class Entity {
	public var level(default, null):Level;
	public var tx(default, null):Int;
	public var ty(default, null):Int;
	public var anim(default, null):Anim;
	public var canBeRolledOn(default, null):Bool = false;
	/**
	 * Was this entity removed this frame? Managed by the level.
	 */
	public var isRemoved(default, default):Bool;
	
	private var _animator:AnimPlayer;

	public function new() {
		anim = new Anim();
		_animator = new AnimPlayer(anim);
	}
	
	public function setPos(tx:Int, ty:Int) {
		this.tx = tx;
		this.ty = ty;
		anim.setPos(tx * GameSprites.SPRITE_SIZE, ty * GameSprites.SPRITE_SIZE);
	}
		
	//// Updating

	public function tick() { }	
	
	//// Killing
	
	/**
	 * Kills this entity.<br>
	 * Default is to remove the entity and spawn an explosion in its place.
	 * 
	 * @param	killer the entity that killed us, might be null if none. 
	 */
	public function explode(killer:Entity=null) {
		level.removeEntity(this);
		level.spawnEntity(new Explosion(), tx, ty);
	}
	
	//// Events
	
	/**
	 * A new level tick is about to happen. Clear any frame flags etc...
	 */
	public function onNewTick() { }
	
	public function onSpawn(level:Level, tx:Int, ty:Int) { 
		this.level = level;		
		setPos(tx, ty);
	}
	
	/**
	 * A collision with another entity has happened.<br>
	 * By default does nothing and returns false (nothin happens and do no block the other entity)
	 * @param	other the entity we are potentialy colliding with
	 * @param	weAreMoving true if this entity is the one move, false if it is the other
	 * @return true if collision is blocking (prevent movement), false if do not block movement.
	 */
	public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		return false;
	}
	
	//// Animations
	
	private function defAnim(name:String, anim:Anim) {
		_animator.defAnim(name, anim);
	}
	
	/**
	 * Makes an animation from game sprites tiles.
	 * @param	sprites
	 * @param	speed
	 * @param	isLooping
	 * @return
	 */
	private function makeAnim(sprites:Array<Int>, speed:Float = 10, isLooping:Bool = false):Anim {
		var a:Anim = new Anim(GameSprites.makeFrames(sprites), speed);
		a.loop = isLooping;
		return a;
	}

	/**
	 * Start or continue an animation.
	 * @param	key
	 * @param	forceRestart
	 */
	private function playAnim(name:String, forceRestart:Bool = false) {
		_animator.playAnim(name, forceRestart);
	}
	
	//// Sfx
	
	private function playSfx(sfx:Sound, vol:Float = 0.5) {
		SfxPlayer.play(sfx, vol);
	}
}