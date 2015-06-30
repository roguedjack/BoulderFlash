package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Level;
import hxd.Res;

/**
 * Amoebas try to grow into adjacent earth or empty tiles and can eat monsters.<br>
 * Amoebas cannot grow in wall/barriers tiles, other amoebas, boulders and the player.<br>
 * When all amoebas in a level cannot grow, the level will explode them into diamonds.<br>
 * If the amoebas count grows too big the level will transform them into rocks.
 * 
 * @author roguedjack
 */
class Amoeba extends Entity {

	public var isTrapped(default, set):Bool;	
	private var _growthCooldown:Int;
	
	static private var GROW_DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1]];

	public function new() {
		super();		
		
		defAnim("trapped", makeAnim([0,8], Gameplay.AMOEBA_ANIM_SPEED, true));
		defAnim("alive", makeAnim([0,8, 1,8, 2,8, 3,8, 4,8, 5,8, 6,8, 7,8], Gameplay.AMOEBA_ANIM_SPEED, true));
		playAnim("alive");
	}
	
	private function set_isTrapped(b:Bool):Bool {
		if (this.isTrapped != b) {
			playAnim(b ? "trapped" : "alive");
		}
		return this.isTrapped = b;
	}
	
	private function cooldown() {
		_growthCooldown += Std.int(Gameplay.AMOEBA_GROWTH_TICKS_MAX_COOLDOWN - Gameplay.AMOEBA_GROWTH_TICKS_MIN_COOLDOWN) + Gameplay.AMOEBA_GROWTH_TICKS_MIN_COOLDOWN;
	}

	override public function onSpawn(level:Level, tx:Int, ty:Int) {
		super.onSpawn(level, tx, ty);
		cooldown();
		isTrapped = false;
		playSfx(Res.sfx.amoeba_spawn);
	}
	
	override public function tick() {				
		// update growth cooldown
		if (_growthCooldown > 0) { 
			--_growthCooldown;
		}
		var isTimeToGrow = _growthCooldown == 0;
		
		// not trapped this frame unless proven otherwise
		isTrapped = false;
		
		// find all adjacent tiles we can grow in
		var growSpots = [];
		var trappedDirCount = 0;
		if (isTimeToGrow) {
			for (dir in GROW_DIRS) {
				var xx = tx + dir[0];
				var yy = ty + dir[1];
				if (canGrowIn(xx, yy)) {
					growSpots.push([xx, yy]);
				} else {
					++trappedDirCount;					
				}
			}
		}

		// trapped if all potential growth directions are trapping.
		if (trappedDirCount == GROW_DIRS.length) {
			isTrapped = true;
			return;
		}
		
		// not trapped, grow if its time.
		if (isTimeToGrow && growSpots.length > 0) {
			// don't grow again soon
			cooldown();
			// randomly pick an available spot to grow in
			var spot = growSpots[Std.random(growSpots.length)];
			var growX = spot[0];
			var growY = spot[1];
			// if a monster is there kill it,
			// otherwise grow by spawning a new amoeba.
			var other = level.getEntityAt(growX, growY);
			if (Std.is(other, Monster)) {
				other.explode();
			} else {
				level.setTile(growX, growY, Tiles.EMPTY);
				level.spawnEntity(new Amoeba(), growX, growY);
			}
		}
	}
	
	/**
	 * Can grow in : empty/earth tiles with no entity or a monster.
	 * @param	xx
	 * @param	yy
	 * @return
	 */
	private function canGrowIn(xx:Int, yy:Int):Bool {
		if (!level.isInBounds(xx, yy)) {
			return false;
		}
		var t = level.getTile(xx, yy);
		if (t != Tiles.EMPTY && t != Tiles.EARTH) {
			return false;
		}
		var other = level.getEntityAt(xx, yy);
		return other == null || Std.is(other, Monster);
	}

	
	/**
	 * Spawns a diamond after exploding.
	 * @param	killer
	 */
	override public function explode(killer:Entity = null) {
		level.removeEntity(this);
		level.spawnEntity(new Explosion(new Diamond()), tx, ty);
	}
	
	/**
	 * Kills monsters, blocks everything.
	 * @param	other
	 * @param	weAreMoving
	 * @return
	 */
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		if (Std.is(other, Monster)) {
			other.explode();
		}
		return true;
	}
}