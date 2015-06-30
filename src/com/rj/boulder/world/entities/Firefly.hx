package com.rj.boulder.world.entities;
import com.rj.boulder.world.Entity;

/**
 * Surrounding tiles and entities explode with a firefly potentially causing chain reactions.
 * 
 * @author roguedjack
 */
class Firefly extends Monster {

	public function new() {
		super();
			
		defAnim("idle", makeAnim([0,9, 1,9, 2,9, 3,9, 4,9, 5,9, 6,9, 7,9], Gameplay.MONSTER_ANIM_SPEED, true));
		playAnim("idle");		
		
		hugWallsOnLeft = true;
	}
	
	/**
	 * Explode all around.
	 * @param	killer
	 */
	override public function explode(killer:Entity = null) {				
		// self explosion
		level.removeEntity(this);
		level.spawnEntity(new Explosion(), tx, ty);
		
		// then explode things around
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
				// explode tile and entity
				level.setTile(xx, yy, Tiles.EMPTY);
				if (other != null) {
					other.explode();
				} else {
					level.spawnEntity(new Explosion(), xx, yy);
				}
			}
		}
	}
}