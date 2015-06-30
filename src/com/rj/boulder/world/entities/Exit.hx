package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import hxd.Res;

/**
 * The exit can be open or locked and starts locked.
 * 
 * @author roguedjack
 */
class Exit extends Entity {
	
	public var isOpen(default, set):Bool = false;

	public function new() {
		super();		
		
		defAnim("locked", makeAnim([1, 6], Gameplay.EXIT_ANIM_SPEED)); 
		defAnim("open", makeAnim([2, 6, 1, 6], Gameplay.EXIT_ANIM_SPEED, true));
		playAnim("locked");
	}
	
	private function set_isOpen(b:Bool):Bool {
		if (isOpen != b ) {
			playAnim(b ? "open" : "locked");
			playSfx(Res.sfx.exit_open);
		}
		
		return this.isOpen = b;
	}
	
	/**
	 * The player wins when colliding with an open exit.
	 * @param	other
	 * @param	weAreMoving
	 * @return
	 */
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		if (isOpen && Std.is(other, Player)) {
			level.removeEntity(this);
			level.win();
			return false;
		}
		return true;
	}
}