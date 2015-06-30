package com.rj.boulder.world.entities;

import com.rj.boulder.render.GameSprites;
import com.rj.boulder.world.Entity;
import h2d.Anim;
import hxd.Res;

/**
 * ...
 * @author roguedjack
 */
class Diamond extends RollingEntity {

	public function new() {
		super();
		
		defAnim("idle", makeAnim([0, 10, 1, 10, 2, 10, 3, 10, 4, 10, 5, 10, 6, 10, 7, 10], Gameplay.DIAMOND_ANIM_SPEED, true));
		playAnim("idle");		
	}
	
	override function onFallStop() {
		playSfx(Res.sfx.diamond_move);
	}
	
	override function roll(dx:Int) {
		playSfx(Res.sfx.diamond_move);
		super.roll(dx);
	}
	
	/**
	 * Collected by player, blocks everyone else.
	 * @param	other
	 * @param	weAreMoving
	 * @return
	 */
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		if (Std.is(other, Player)) {
			collectMe();
			return false;
		}
		return true;
	}
	
	public function collectMe() {
		playSfx(Res.sfx.player_collect_diamond);
		level.collectDiamond(this);		
	}
}