package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Level;
import hxd.Res;

/**
 * An explosion blocks everything and can spawn another entity when ended.<br>
 * This allows for instance butterflies to transform into diamonds after exploding.
 * 
 * @author roguedjack
 */
class Explosion extends Entity
{
	private var _playload:Entity;
	private var _hasEnded:Bool;

	/**
	 * 
	 * @param	playload the entity to spawn at our place when the explosion is done
	 */
	public function new(playload:Entity=null) {
		super();		
		_playload = playload;
		
		defAnim("explode", makeAnim([4,7, 3,7], Gameplay.EXPLOSION_ANIM_SPEED));
		playAnim("explode");
		anim.onAnimEnd = function() { _hasEnded = true; }
	}
	
	override public function onSpawn(level:Level, tx:Int, ty:Int) {
		super.onSpawn(level, tx, ty);
		playSfx(Res.sfx.explosion);
	}
	
	/**
	 * Blocks everything.
	 * @param	other
	 * @param	weAreMoving
	 * @return
	 */
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		return true;
	}

	/**
	 * When animation ends, remove self and spawn payload.
	 */
	override public function tick() {
		if (_hasEnded) {
			level.removeEntity(this);
			if (_playload != null) {
				level.spawnEntity(_playload, tx, ty);
			}
		}
	}
}