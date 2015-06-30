package com.rj.boulder.world.entities;

import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Level;

/**
 * ...
 * @author roguedjack
 */
class Monster extends Entity {
	
	/**
	 * Does this monster prefers hugging walls on his left or right?
	 */
	public var hugWallsOnLeft(default, null):Bool;
	private var _dirX:Int;
	private var _dirY:Int;	

	public function new() {
		super();
	}
	
	/*
	override public function onSpawn(level:Level, tx:Int, ty:Int) {
		super.onSpawn(level, tx, ty);
		FIXME -- this doesnt work for Butterflies on all levels, the starting direction must be a data in the level, rules doesn't do it
		// S4L1 : counterclockwise, must start going LEFT
		// S5L1 : counterclockwise, must start going RIGHT
		if (hugLeftWalls) {
			_dirX = 1;
			_dirY = 0;
		} else {
			_dirX = -1;
			_dirY = 0;			
		}
	}
	*/
	
	public override function tick() {	
		// Helpers, makes logic more clear
		function turn() {
			hugWallsOnLeft ? turnLeft() : turnRight();
		}
	
		function turnReverse() {
			hugWallsOnLeft ? turnRight() : turnLeft();
		}
		
		function getPosOnTurn(): { xx:Int, yy:Int } {			
			var dx = _dirX;
			var dy = _dirY;
			turn();
			var xx = tx + _dirX;
			var yy = ty + _dirY;
			_dirX = dx;
			_dirY = dy;
			return { xx:xx, yy:yy };
		}
		
		function isWallOnHugSide() {
			var side = getPosOnTurn();
			var t = level.getTile(side.xx, side.yy);
			return t == Tiles.BARRIER || t == Tiles.WALL;
		}
		
		function canMoveForward() {
			return canMonsterMoveIn(tx + _dirX, ty + _dirY);
		}
		
		function moveForward() {
			level.moveEntity(this, tx + _dirX, ty + _dirY);
		}
		
		function canMoveOnHugSide() {
			var side = getPosOnTurn();
			return canMonsterMoveIn(side.xx, side.yy);
		}
		
		// Logic
		
		// find a wall to hug right after spawning
		if (_dirX == 0 && _dirY == 0) {
			var up = canMonsterMoveIn(tx, ty - 1);
			var down = canMonsterMoveIn(tx, ty +1);
			var left = canMonsterMoveIn(tx - 1, ty);
			var right = canMonsterMoveIn(tx + 1, ty);
			if (hugWallsOnLeft) {
				if (!up) 			{ _dirX = 1; }
				else if (!down) 	{ _dirX = -1; }
				else if (!left)		{ _dirY = -1; }
				else if (!right) 	{ _dirY = 1; }
				else 			 	{ _dirX = -1; }
			} else {
				if (!up) 			{ _dirX = -1; }
				else if (!down) 	{ _dirX = 1; }
				else if (!left)		{ _dirY = 1; }
				else if (!right) 	{ _dirY = -1; }
				else 			 	{ _dirX = 1; }				
			}
		}

		// keep hugging a wall if we can
		if (isWallOnHugSide()) {
			if (canMoveForward()) {
				// keep hugging the wall.
				moveForward();
			} else {
				// wall on side and front, we are in a corner.
				turnReverse();
			}
			return;
		} 
		
		// move on hug side if we can so we take intersections,
		// otherwise keep going forward and turn if blocked.
		if (canMoveOnHugSide()) {
			// take the intersection.
			turn();
			moveForward();
		} else {
			if (canMoveForward()) {
				moveForward();
			} else {
				turnReverse();
			}
		}		
	}	

	/**
	 * Kills the player, blocks everything.
	 * @param	other
	 * @param	weAreMoving
	 * @return
	 */
	override public function onCollisionWith(other:Entity, weAreMoving:Bool):Bool {
		if (Std.is(other, Player)) {
			other.explode();
		}
		return true;
	}
	
	/**
	 * Can move on empty tiles and entities it can eat.
	 * @param	tx
	 * @param	ty
	 * @return
	 */
	private function canMonsterMoveIn(tx:Int, ty:Int):Bool {
		var t = level.getTile(tx, ty);
		if (t != Tiles.EMPTY) {
			return false;
		}
		var other = level.getEntityAt(tx, ty);
		return other == null || canMonsterEat(other);
	}
	
	/**
	 * Can eat the player and *try* to eat amoebas because monsters are stupid :-]
	 * @param	other
	 * @return
	 */
	private function canMonsterEat(other:Entity):Bool {
		return Std.is(other, Player) || Std.is(other, Amoeba);
	}
	
	private function turnRight() {
		switch ([_dirX, _dirY]) {
			case [-1, 0]:  // going left
				_dirX = 0;
				_dirY = -1;
			case [1, 0]:  // going right
				_dirX = 0;
				_dirY = 1;
			case [0, -1]:  // going up
				_dirX = 1;
				_dirY = 0;
			case [0, 1]: // going down
				_dirX = -1;
				_dirY = 0;
			default:
				throw "invalid monster direction!";							
		}
	}
	
	private function turnLeft() {
		switch ([_dirX, _dirY]) {
			case [-1, 0]:  // going left
				_dirX = 0;
				_dirY = 1;
			case [1, 0]:  // going right
				_dirX = 0;
				_dirY = -1;
			case [0, -1]:  // going up
				_dirX = -1;
				_dirY = 0;
			case [0, 1]: // going down
				_dirX = 1;
				_dirY = 0;
			default:
				throw "invalid monster direction!";							
		}
	}	

}