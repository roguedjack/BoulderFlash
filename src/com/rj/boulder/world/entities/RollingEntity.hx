package com.rj.boulder.world.entities;
import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Level;

/**
 * Entities that can fall, roll and crush other entities below.<br>
 * Ex: rocks and diamonds.<br>
 * They can also fall on magic walls.
 * 
 * @author roguedjack
 */
class RollingEntity extends Entity {
	
	public var isFallingDown(default, null):Bool;
	private var _wasPushedThisFrame:Bool = false;
	
	private function new() {
		super();
		
		canBeRolledOn = true;
	}
	
	override public function onSpawn(level:Level, tx:Int, ty:Int) {
		super.onSpawn(level, tx, ty);
		
		isFallingDown = false;
	}
	
	override public function onNewTick() {
		_wasPushedThisFrame = false;
	}
	
	/**
	 * This entity has been pushed.
	 */
	public function onPushed() {
		_wasPushedThisFrame = true;
	}

	/**
	 * Fall and roll. Falling may crush other entities. Dispatch collision event only to magic walls.
	 * 
	 * @param	elapsed
	 */
	override public function tick() {			
		// don't move if we have been pushed this frame.
		// we don't want to change position twice in the same frame!
		if (_wasPushedThisFrame) {
			return;
		}		
		
		if (level.isEmptyAt(tx, ty + 1)) {
			fall();
		} else {
			if (isFallingDown) {
				isFallingDown = false;
				
				var otherBelowMe:Entity = level.getEntityAt(tx, ty + 1);
				if (otherBelowMe != null) {
					if (canCrush(otherBelowMe)) {
						onCrush(otherBelowMe);
					} else if (Std.is(otherBelowMe, MagicWall)) {
						cast(otherBelowMe, MagicWall).onCollisionWith(this, false);
					}
				}
				onFallStop();
			}
			if (level.canRollOn(tx, ty + 1)) {
				if (level.isEmptyAt(tx - 1, ty) && level.isEmptyAt(tx - 1, ty + 1)) {
					roll(-1);
				} else if (level.isEmptyAt(tx + 1, ty) && level.isEmptyAt(tx + 1, ty + 1)) {
					roll(1);
				}
			}
		}
	}
	
	private function onFallStop() { }
	
	/**
	 * We are falling on another entity, can we crush it?<br>
	 * Default is to crush player and monsters.
	 * @param	other
	 * @return
	 */
	private function canCrush(other:Entity):Bool {
		if (Std.is(other, Player) || Std.is(other, Monster)) {
			return true;
		}
		return false;		
	}
	
	/**
	 * Crush an entity we are falling on.<br>
	 * Default is to kill it.
	 * @param	other
	 */
	private function onCrush(other:Entity) {		
		other.explode(this);
	}
	
	private function fall() {
		isFallingDown = true;
		level.moveEntity(this, tx, ty + 1);		
	}
	
	private function roll(dx:Int) {		
		level.moveEntity(this, tx + dx, ty);
	}
	
}