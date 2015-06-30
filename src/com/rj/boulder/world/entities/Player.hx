package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Level;
import com.rj.heaps.Keys;
import haxe.rtti.CType.Rights;
import hxd.Key;
import hxd.Res;

enum PlayerState {
	WAITING_TO_SPAWN;
	SPAWNING;
	PLAYING;
	WON_LEVEL;
	DEAD;
}

/**
 * The player entity.<br>
 * The player is not managed like other entities by the level. It is ticked every frame and has the responsability to
 * manage its own tick timer. This makes the game more responsive to the player input and much less frustrating :-]
 * @author roguedjack
 */
class Player extends Entity {	

	public var state(default, null):PlayerState;
	private var _spawnDelay:Float;
	private var _moveCooldown:Float;
	private var _wasGoingLeft:Bool;

	public function new() 	{
		super();
		
		defAnim("limbo", makeAnim([1, 6,  2, 6], Gameplay.EXIT_ANIM_SPEED, true));
		defAnim("spawn", makeAnim([1, 0, 1, 0, 2, 0, 2, 0, 3, 0, 3, 0], Gameplay.PLAYER_ANIM_SPEED));
		defAnim("idle", makeAnim([0,1, 1,1, 2,1, 3,1, 4,1, 5,1, 6,1, 7,1, 0,2, 1,2, 2,2, 3,2, 4,2, 5,2, 6,2, 7,2, 0,3, 1,3, 2,3, 3,3, 4,3, 5,3, 6,3, 7,3], Gameplay.PLAYER_ANIM_SPEED, true));
		defAnim("walkLeft", makeAnim([0,4, 1,4, 2,4, 3,4, 5,4, 6,4, 7,4], Gameplay.PLAYER_ANIM_SPEED, true));
		defAnim("walkRight", makeAnim([0, 5, 1, 5, 2, 5, 3, 5, 5, 5, 6, 5, 7, 5], Gameplay.PLAYER_ANIM_SPEED, true));
		playAnim("limbo");
	}
	
	override public function onSpawn(level:Level, tx:Int, ty:Int) {
		super.onSpawn(level, tx, ty);
				
		_moveCooldown = 0;
		
		// start in limbo, waiting to spawn.
		_spawnDelay = Gameplay.PLAYER_SPAWN_WAIT_DELAY;
		playAnim("limbo");
		state = PlayerState.WAITING_TO_SPAWN;
	}

	override public function explode(killer:Entity = null) {
		super.explode(killer);
		state = PlayerState.DEAD;
		level.loseLife();
	}
	
	public function onWinLevel() {
		state = PlayerState.WON_LEVEL;
	}
	
	/**
	 * The player is ticked every frame by the level. An idle player will respond immediatly to inputs, a player that has
	 * acted recently will skip frames.
	 * 
	 */
	override public function tick() {		
		// if in limbo, check if time to appear.
		if (state == PlayerState.WAITING_TO_SPAWN) {
			if ((_spawnDelay -= level.elapsed) <= 0) {
				state = PlayerState.SPAWNING;				
				playAnim("spawn");
				anim.onAnimEnd = function() {
					if (state == PlayerState.SPAWNING && _animator.currentAnim == "spawn") {
						state = PlayerState.PLAYING;
						anim.onAnimEnd = function() {}
						playSfx(Res.sfx.player_spawn);
						playAnim("idle");
					}
				};
			}
			return;
		}
		
		// if not ready to play (spawning, dead, won),  don't.
		if (state != PlayerState.PLAYING) {
			return;
		}
		
		// if level time out, kill!
		if (level.timeLeft <= 0) {
			explode();
			return;
		}
		
		// suicide? :(
		if (Keys.anyKeyDown(Gameplay.KEYS_SUICIDE)) {
			explode();
			return;
		}		
		
		// update internal action timer
		_moveCooldown -= level.elapsed;		
		// if still cooling down, skip this frame.
		if (_moveCooldown > 0) {
			return;
		}		

		// movement & action
		var up = Keys.anyKeyDown(Gameplay.KEYS_UP);
		var down = Keys.anyKeyDown(Gameplay.KEYS_DOWN);
		var left = Keys.anyKeyDown(Gameplay.KEYS_LEFT);
		var right = Keys.anyKeyDown(Gameplay.KEYS_RIGHT);
		var action = Keys.anyKeyDown(Gameplay.KEYS_ACTION);		
		if (up && down) {
			up = down = false;
		}
		if (left && right) {
			left = right = false;
		}
		if ((up || down) && (left || right)) { // forbid diagonals and up/down has priority
			left = right = false;
		}		
		var moving = (up || down || left || right);
		action = action && moving;
		var idle = !(moving || action);
		var dx = left ? -1 : right ? 1 : 0;
		var dy = up ? -1 : down ? 1 : 0;		
					
		// animate movement
		if (idle) {
			playAnim("idle");
		} else if (left) {
			_wasGoingLeft = true;			
			playAnim("walkLeft");
		} else if (right) {
			_wasGoingLeft = false;			
			playAnim("walkRight");
		} else if (up || down) {
			playAnim(_wasGoingLeft ? "walkLeft": "walkRight");
		}
		
		// make the move/action
		// acting sets the cooldown timer.
		// pushing the action key performs the action without moving the player (ex: digging an adjacent tile)
		if (!idle) {			
			// delay next action
			_moveCooldown = 1.0 / Gameplay.PLAYER_TICKS_PER_SECOND;
			
			var toTx = tx + dx;
			var toTy = ty + dy;			
			var moveMe = false;
			var sfx = null;
			
			if (level.isEmptyAt(toTx, toTy)) {
				// move
				moveMe = !action;
				sfx = Res.sfx.player_walk;
			} else if (level.canDigAt(toTx, toTy)) {
				// dig
				level.digAt(toTx, toTy);
				moveMe = !action;
				sfx = Res.sfx.player_dig;
			} else if (level.isBlockingTileAt(toTx, toTy)) {
				// blocked by wall/barrier			
				moveMe = false;
				sfx = Res.sfx.player_walk;
			} else if (level.isDiamondAt(toTx, toTy)) {
				// pick up an adjacent diamond vs moving in
				if (action) {
					moveMe = false;
					(cast(level.getEntityAt(toTx, toTy), Diamond)).collectMe();
				} else {
					// we'l collect the diamond when moving in (collision)
					moveMe = true;
				}
			} else if (dy == 0 && level.isEntityAtPushableTo(toTx, ty, dx)) {
				// push left/right
				level.pushEntity(cast(level.getEntityAt(toTx, ty), RollingEntity), dx);
				moveMe = !action;
				sfx = Res.sfx.player_dig;
			}  else if (moving && level.getEntityAt(toTx, toTy) != null) {
				// collide the entity
				moveMe = true;
				sfx = Res.sfx.player_walk;
			}
			
			if (sfx != null) {
				playSfx(sfx);
			}
			if (moveMe) {
				level.moveEntity(this, toTx, toTy);
			}			
		}
	}

}