package com.rj.boulder.world.entities;

import com.rj.boulder.render.GameSprites;
import com.rj.boulder.world.Entity;
import h2d.Anim;
import hxd.Res;

/**
 * ...
 * @author roguedjack
 */
class Boulder extends RollingEntity {

	public function new() {
		super();

		defAnim("idle", makeAnim([0, 7]));
		playAnim("idle");		
	}
	
	override function onFallStop() {
		playSfx(Res.sfx.boulder_move);
	}	
	
	override function roll(dx:Int) {
		playSfx(Res.sfx.boulder_move);
		super.roll(dx);
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
}