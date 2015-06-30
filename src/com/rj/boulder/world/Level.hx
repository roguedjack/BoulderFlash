package com.rj.boulder.world;

import com.rj.boulder.world.EditorTiles;
import com.rj.boulder.world.entities.Amoeba;
import com.rj.boulder.world.entities.Boulder;
import com.rj.boulder.world.entities.Butterfly;
import com.rj.boulder.world.entities.Diamond;
import com.rj.boulder.world.entities.Exit;
import com.rj.boulder.world.entities.Explosion;
import com.rj.boulder.world.entities.Firefly;
import com.rj.boulder.world.entities.MagicWall;
import com.rj.boulder.world.entities.Player;
import com.rj.boulder.world.entities.RollingEntity;
import com.rj.boulder.world.Level.LevelListener;
import com.rj.boulder.world.Tiles;
import haxe.ds.ArraySort;
import hxd.res.TiledMap;

using com.rj.heaps.TiledMapExtenders;


interface LevelListener {
	public function onTileChanged(tx:Int, ty:Int):Void;
	public function onEntitySpawned(e:Entity):Void;
	public function onEntityRemoved(e:Entity):Void;
	public function onEntityMoved(e:Entity):Void;
	public function onThemeChanged(newTheme:LevelTheme):Void;
	public function onExitOpened():Void;
	public function onLevelWon():Void;
	public function onLifeLost():Void;
}

enum LevelTheme {
	DEFAULT;
	RED;
	GREEN;	
	BLUE;
}

typedef LevelProps = {
	var name:String;
	var theme:LevelTheme;
	var diamondsRequired:Int;
	var timer:Int;
}

/**
 * ...
 * @author roguedjack
 */
class Level {
	public var name(default, null):String;
	public var theme(default, set):LevelTheme;		
	public var timer(default, null):Float;
	public var timeLeft(default, null):Float;
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var entities(get, null):Array<Entity>;
	public var diamondsRequired(default, null):Int;
	public var diamondsTaken(default, null):Int;	
	public var player(get, never):Player;
	public var isExitOpened(default, null):Bool;
	public var elapsed(default, null):Float;	
	private var _listeners:Array<LevelListener>;
	private var _tiles:Array<Tiles>;
	private var _entitiesList:Array<Entity>;
	private var _entitiesGrid:Array<Entity>;
	private var _pendingRemovals:Array<Entity>;
	private var _doEntitiesNeedSorting:Bool = true;
	private var _playerRef:Player;
	private var _exitRef:Exit;
	private var _tickTimer:Float;	
	private var _amoebasTotalCount:Int;
	private var _hasWon:Bool;
	
	public function new(props:LevelProps, width:Int, height:Int) {
		this.width = width;
		this.height = height;		
		this.theme = props.theme;
		this.name = props.name;
		this.diamondsRequired = props.diamondsRequired;
		this.timer = props.timer;
		_listeners = [];
		_tiles = [];
		_entitiesList = [];
		_entitiesGrid = [];
		_amoebasTotalCount = 0;
	}
	
	private function get_entities():Array<Entity> {
		return _entitiesList;
	}
	
	private function get_player():Player {
		return _playerRef;
	}	
	
	private function set_theme(t:LevelTheme):LevelTheme {
		if (_listeners != null) {
			for (l in _listeners) {
				l.onThemeChanged(t);
			}
		}
		return this.theme = t;
	}
	
	//// Listeners
	
	public function addListener(l:LevelListener) {
		_listeners.push(l);
	}
	
	public function removeListener(l:LevelListener) {
		_listeners.remove(l);
	}
	
	//// Starting & Winning/Losing
	
	public function start() {
		diamondsTaken = 0;
		timeLeft = timer;		
		_tickTimer = 0;
	}
	
	public function win() {
		_hasWon = true;
		if (_playerRef != null && _playerRef.state == PlayerState.PLAYING) {
			_playerRef.onWinLevel();
		}
		
		for (l in _listeners) {
			l.onLevelWon();
		}
	}
	
	public function loseLife() {
		for (l in _listeners) {
			l.onLifeLost();
		}
	}

	//// Tiles
	
	/**
	 * 
	 * @param	tx
	 * @param	ty
	 * @return BARRIER if out of bounds.
	 */
	public function getTile(tx:Int, ty:Int):Tiles {
		return isInBounds(tx, ty) ? _tiles[index(tx, ty)] : Tiles.BARRIER;
	}
	
	public function setTile(tx:Int, ty:Int, t:Tiles) {
		_tiles[index(tx, ty)] = t;
		for (l in _listeners) {
			l.onTileChanged(tx, ty);
		}
	}
	
	public function isInBounds(tx:Int, ty:Int):Bool {
		return tx >= 0 && tx < width && ty >= 0 && ty < height;
	}
	
	private inline function index(tx:Int, ty:Int):Int {
		return tx + ty * width;
	}
	
	//// Entities
	
	public function spawnEntity(e:Entity, tx:Int, ty:Int) {
		_entitiesList.push(e);
		_entitiesGrid[index(tx, ty)] = e;
		_doEntitiesNeedSorting = true;	
		
		// monitor entities of interest
		if (Std.is(e, Player)) {
			_playerRef = cast(e, Player);
		} else if (Std.is(e, Exit)) {
			_exitRef = cast(e, Exit);
		} else if (Std.is(e, Amoeba)) {
			++_amoebasTotalCount;
		}
		
		e.onSpawn(this, tx, ty);
		for (l in _listeners) {
			l.onEntitySpawned(e);
		}
	}
	
	public function removeEntity(e:Entity) {
		e.isRemoved = true;
		_entitiesGrid[index(e.tx, e.ty)] = null;
		
		// monitor entities of interest
		if (Std.is(e, Amoeba)) {
			--_amoebasTotalCount;
		}
		
		for (l in _listeners) {
			l.onEntityRemoved(e);
		}
	}
	
	/**
	 * 
	 * @param	tx
	 * @param	ty
	 * @return null if no entity or out of bounds.
	 */
	public function getEntityAt(tx:Int, ty:Int):Entity {
		if (isInBounds(tx, ty)) {
			return _entitiesGrid[index(tx, ty)];
		} else {
			return null;
		}
	}
	
	/**
	 * Try to move the entity, checking and resolving collisions.<br>
	 * Does not check for blocking tiles, it is assumed the moving entity has checked the tiles and they might have their own rules.
	 * @param	e
	 * @param	toTx
	 * @param	toTy
	 */
	public function moveEntity(e:Entity, toTx:Int, toTy:Int) {
		// check collision with another entity there
		var blocked = false;
		var other = getEntityAt(toTx, toTy);
		if (other != null) {
			// dispatch collisions
			if (e.onCollisionWith(other, true)) {
				blocked = true;
			}
			if (other.onCollisionWith(e, true)) {
				blocked = true;
			}
		}
		// if not blocked, do the move.
		if (!blocked) {
			_entitiesGrid[index(e.tx, e.ty)] = null;
			_entitiesGrid[index(toTx, toTy)] = e;
			_doEntitiesNeedSorting = true;
			e.setPos(toTx, toTy);			
			// make sure the other entity was removed, we don't allow two active entities on the same tile.
			if (other != null && !other.isRemoved) {
				throw "entity " + other + " authorized " + e+" to move in but was not removed by the collision!";
			}
		}
		
		// notify move
		for (l in _listeners) {
			l.onEntityMoved(e);
		}
	}
	
	/**
	 * Sort entities by position so the entities at the bottom right will be updated first.<br>
	 * This ensures falling entities fall correctly.
	 */
	private function sortEntitiesByTickOrder() {	
		// use ArraySort vs array.sort because we need stable order
		ArraySort.sort(_entitiesList, function (e1:Entity, e2:Entity):Int {
			return e1.ty > e2.ty ? -1 : 
				e1.ty < e2.ty ? 1 : 
				e1.tx < e2.tx ? -1 :
				e1.tx > e2.tx ? 1 :
				0;				
		});
	}
	
	///// Rules 
	
	/**
	 * Check if tile is of type empty and is not occupied by an entity.
	 * @param	tx
	 * @param	ty
	 * @return
	 */
	public function isEmptyAt(tx:Int, ty:Int):Bool {
		return getTile(tx, ty) == Tiles.EMPTY && getEntityAt(tx, ty) == null;
	}
	
	/**
	 * Can roll on walls and "canBeRolledOn" entities.
	 * @param	tx
	 * @param	ty
	 * @return
	 */
	public function canRollOn(tx:Int, ty:Int):Bool {
		if (getTile(tx, ty) == Tiles.WALL) {
			return true;
		}
		var e = getEntityAt(tx, ty);
		return e != null && e.canBeRolledOn;
	}
	
	public function canDigAt(tx:Int, ty:Int):Bool {
		return getTile(tx, ty) == Tiles.EARTH && getEntityAt(tx, ty) == null;
	}
	
	public function digAt(tx:Int, ty:Int) {
		setTile(tx, ty, Tiles.EMPTY);
	}
	
	public function isBlockingTileAt(tx:Int, ty:Int):Bool {
		var t = getTile(tx, ty);
		return t == Tiles.BARRIER || t == Tiles.WALL;
	}

	public function isDiamondAt(tx:Int, ty:Int):Bool {
		return Std.is(getEntityAt(tx,ty), Diamond);
	}
	
	public function collectDiamond(diamond:Diamond) {
		removeEntity(diamond);
		++diamondsTaken;
		if (diamondsTaken >= diamondsRequired && !_exitRef.isOpen) {			
			openExit();
		}
	}
	
	public function openExit() { 
		if (_exitRef == null || _exitRef.isOpen) {
			return;
		}
		_exitRef.isOpen = true;		
		for (l in _listeners) {
			l.onExitOpened();
		}
	}

	/**
	 * Check if there is an entity at (tx,ty) that can be pushed left or right.<br>
	 * Only RollingEntities can be pushed.
	 * @param	tx
	 * @param	ty
	 * @param	dx -1/+1
	 * @return
	 */
	public function isEntityAtPushableTo(tx:Int, ty:Int, dx:Int):Bool {
		if (dx != -1 && dx != 1) { // sanity check!
			return false;
		}
		var e = getEntityAt(tx, ty);
		if (e == null) {
			return false;
		}
		if (!isEmptyAt(tx + dx, ty)) {
			return false;
		}
		return Std.is(e, RollingEntity);
	}
	
	/**
	 * Push a rolling entity.
	 * @param	e
	 * @param	dx
	 */
	public function pushEntity(e:RollingEntity, dx:Int) {
		moveEntity(e, e.tx + dx, e.ty);
		e.onPushed();
	}
	
	//// Updating	
	
	public function update(elapsed:Float) {
		this.elapsed = elapsed;
		
		// update timer if player is playing
		if (_playerRef != null && _playerRef.state == PlayerState.PLAYING) {
			if (timeLeft > 0) {
				timeLeft -= elapsed;
			} else {
				timeLeft = 0;
			}
		}

		// always tick the player each frame
		if (_playerRef != null && !_playerRef.isRemoved) {
			_playerRef.onNewTick();
			_playerRef.tick();
		}
		
		// tick all other things periodically
		_tickTimer += elapsed;
		if (_tickTimer >= 1.0 / Gameplay.LEVEL_TICKS_PER_SECOND) {
			tick();
			_tickTimer -= 1.0 / Gameplay.LEVEL_TICKS_PER_SECOND;
		}
	}
	
	private function tick() {		
		// sort entities if we need to
		if (_doEntitiesNeedSorting) {
			sortEntitiesByTickOrder();
			_doEntitiesNeedSorting = false;
		}
					
		// notify entities of a new tick
		for (e in _entitiesList) {
			if (e == _playerRef) {
				continue;
			}
			e.onNewTick();
		}
		
		// update entities.
		_pendingRemovals = [];
		var amoebasTrappedCount = 0;
		for (e in _entitiesList) {
			if (e == _playerRef) {
				continue;
			}			
			if (!e.isRemoved) {
				e.tick();
				if (_amoebasTotalCount > 0 && Std.is(e, Amoeba) && cast(e, Amoeba).isTrapped) {
					++amoebasTrappedCount;
				}
			}
		}

		// manage amoebas
		if (_amoebasTotalCount > 0) {
			// if all amoebas are trapped, explode them all!		
			if (amoebasTrappedCount > 0 &&  amoebasTrappedCount >= _amoebasTotalCount) {
				for (e in _entitiesList) {
					if (Std.is(e, Amoeba) && !e.isRemoved) {
						e.explode();
					}
				}
			}
			// if amoebas have grown too big, turn them into rocks!
			if (amoebasTrappedCount >= Gameplay.AMOEBA_TOO_BIG_COUNT) {
				for (e in _entitiesList) {
					if (Std.is(e, Amoeba) && !e.isRemoved) {
						removeEntity(e);
						spawnEntity(new Explosion(new Boulder()), e.tx, e.ty);
					}
				}
			}
		}
		
		
		// do pending removals
		if (_pendingRemovals.length > 0) {
			for (e in _pendingRemovals) {
				_entitiesList.remove(e);
			}
			_pendingRemovals = [];
		}
	}

	//// Loading from tiled maps
	
	static public function loadFromTiled(map:TiledMap):Level {
		var data:TiledMapData = map.toMap();
		var mapProps = map.readProperties();
		
		function parseProps(mapProps):LevelProps {
			var name = mapProps.get("name");			
			var theme = mapProps.get("theme") == null  ? LevelTheme.DEFAULT : LevelTheme.createByName(mapProps.get("theme"));			
			var diamonds = Std.parseInt(mapProps.get("diamondsRequired"));
			var timer = Std.parseInt(mapProps.get("timer"));		
			#if debug
			trace("map theme is " + theme);
			trace("map name is " + name);			
			trace("map diamonds required = " + diamonds);			
			trace("map timer = " + timer);
			#end			
			return { name:name, theme:theme, diamondsRequired:diamonds, timer:timer };
		}	
		
		function mapError(msg:String) {
			trace("MAP ERROR "+msg);
			throw msg;
		}
		
		var level = new Level(parseProps(mapProps), data.width, data.height);
		var hasStart = false;
		var hasExit = false;
		
		var tiles = data.layers[0];
		for (ty in 0...level.height) {
			var index = ty * level.width;
			for (tx in 0...level.width) {
				var t:Tiles = Tiles.EMPTY;
				var ted = tiles.data[index];
				var e:Entity = null;
				switch (ted) {
					case EditorTiles.EMPTY, EditorTiles.NULL:
						/* empty tile */						
					case EditorTiles.BARRIER:
						t = Tiles.BARRIER;
					case EditorTiles.EARTH:
						t = Tiles.EARTH;
					case EditorTiles.WALL:
						t = Tiles.WALL;
					case EditorTiles.PLAYER_EXIT:
						if (hasExit) {
							mapError("more than one exit");
						}
						hasExit = true;
						e = new Exit();
					case EditorTiles.PLAYER_START:
						if (hasStart) {
							mapError("more than one start");
						}
						hasStart = true;
						e = new Player();
					case EditorTiles.ENT_BOULDER:
						e = new Boulder();
					case EditorTiles.ENT_DIAMOND:
						e = new Diamond();
					case EditorTiles.ENT_FIREFLY:
						e = new Firefly();
					case EditorTiles.ENT_BUTTERFLY:
						e = new Butterfly();
					case EditorTiles.ENT_AMOEBA:
						e = new Amoeba();
					case EditorTiles.ENT_MAGICWALL:
						e = new MagicWall();
					default:
						mapError("invalid tile value " + ted + " at " + tx + "," + ty);
				}
				level.setTile(tx, ty, t);
				if (e != null) {
					level.spawnEntity(e, tx, ty);
				}
				++index;
			}
		}
		
		if (!hasStart) {
			mapError("missing start position");
		}
		if (!hasExit) {
			mapError("missing exit position");
		}
		
		return level;
	}
	
	
}