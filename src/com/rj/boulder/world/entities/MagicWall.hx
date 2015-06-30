package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import hxd.Res;


/**
 * Turns passing falling boulder into diamonds and diamonds into boulders.<br>
 * Activated at the first collision for a limited period of time, transforming
 * then into a solid wall when time out.<br>
 * Activating a magic wall chain activates all the magic walls in the level.
 * 
 * @author roguedjack
 */
class MagicWall extends Entity {
	
	var _isActivated:Bool;
	var _activationCountdown:Float;

	public function new() {
		super();
		
		defAnim("idle", makeAnim([4,6]));
		defAnim("activated", makeAnim([5,6, 6,6, 7,6], Gameplay.MAGICWALL_ANIM_SPEED, true));
		playAnim("idle");
	}
	
	override public function tick() {
		if (!_isActivated) {
			return;
		}
		
		if (--_activationCountdown <= 0) {
			deactivate();
			return;
		}
	}
	
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {				
		// transform boulder/diamonds
		var transformOther:Entity = null;
		var sfx = null;
		if (Std.is(other, Boulder)) {
			transformOther = new Diamond();
			sfx = Res.sfx.diamond_move;
		} else if (Std.is(other, Diamond)) {
			transformOther = new Boulder();
			sfx = Res.sfx.boulder_move;
		}
		
		if (transformOther != null) {
			if (!_isActivated) {
				activate();
				activateAllOthers();
			}
			level.removeEntity(other);
			var below = ty + 1;
			if (level.isEmptyAt(tx, below)) {
				level.spawnEntity(transformOther, tx, below);
				playSfx(sfx);
			}
		}
		
		// blocks everything
		return true;
	}
	
	/**
	 * Starts activation.
	 */
	function activate() {		
		_isActivated = true;		
		_activationCountdown = Gameplay.MAGICWALL_ACTIVE_TICKS;
		playAnim("activated");
		playSfx(Res.sfx.magicwall_activate);
	}
	
	/**
	 * Remove and replace with a wall tile.
	 */
	function deactivate() {
		_isActivated = false;
		level.removeEntity(this);
		level.setTile(tx, ty, Tiles.WALL);
		playSfx(Res.sfx.magicwall_deactivate);
	}
		
	function activateAllOthers() {
		for (e in level.entities) {
			if (!e.isRemoved && Std.is(e, MagicWall)) {
				var other = cast(e, MagicWall);
				if (!other._isActivated) {
					other.activate();
				}
			}
		}
	}
}