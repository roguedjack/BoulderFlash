package com.rj.boulder.world.entities;
import com.rj.boulder.world.Entity;

/**
 * Butterflies explode into diamonds.
 * 
 * @author roguedjack
 */
class Butterfly extends Monster {

	public function new() {
		super();
			
		defAnim("idle", makeAnim([0,11, 1,11, 2,11, 3,11, 4,11, 5,11, 6,11, 7,11], Gameplay.MONSTER_ANIM_SPEED, true));
		playAnim("idle");		
		
		hugWallsOnLeft = false;
	}

	/**
	 * Explode into diamonds in the tile and around. Entities are removed but not exploded.
	 * @param	killer
	 */
	override public function explode(killer:Entity = null) {
		// explode into diamond
		level.removeEntity(this);
		level.spawnEntity(new Explosion(new Diamond()), tx, ty);
		
		// then explode things into diamonds
		for (yy in ty - 1...ty + 2) {
			for (xx in tx - 1...tx + 2) {
				if (xx == tx && yy == ty) {
					continue;
				}
				if (!level.isInBounds(xx, yy)) {
					continue;
				}
				// can't explode barriers
				if (level.getTile(xx, yy) == Tiles.BARRIER) {
					continue;
				}
				// don't explode if an explosion already there!
				var other = level.getEntityAt(xx, yy);
				if (Std.is(other, Explosion)) {
					continue;
				}	
				// explode to diamond
				// an entity is removed but not exploded.
				// the only exception is the player because we want him to get killed properly
				level.setTile(xx, yy, Tiles.EMPTY);
				if (other != null) {
					if (Std.is(other, Player)) {
						other.explode();
					} else {
						level.removeEntity(other);
					}
				}				
				level.spawnEntity(new Explosion(new Diamond()), xx, yy);
			}
		}		
	}
}