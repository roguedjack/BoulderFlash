package com.rj.boulder.screens;

import com.rj.boulder.Main;
import com.rj.boulder.render.Hud;
import com.rj.boulder.render.LevelView;
import com.rj.boulder.Screen;
import com.rj.boulder.world.entities.Amoeba;
import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Gameplay;
import com.rj.boulder.world.Level;
import com.rj.boulder.world.Tiles;
import h2d.Console;
import hxd.res.FontBuilder;
import hxd.Stage;
import hxd.Timer;
import hxd.WaitEvent;


/**
 * ...
 * @author roguedjack
 */
class PlayScreen extends Screen implements LevelListener {

	private var _level:Level;
	private var _view:LevelView;
	private var _hud:Hud;
	private var _waiter:WaitEvent;
	#if debug
	private var _devConsole:Console;
	#end
	
	public function new(game:Main) {
		super(game);
	
		#if debug
		createDevConsole();
		#end
	}
	
	override public function onEnter() {
		_level = Level.loadFromTiled(Gameplay.MAP_CYCLE[Gameplay.CURRENT_MAP]);
		_level.start();
		_level.addListener(this);
		_waiter = new WaitEvent();		
		_view = new LevelView(_level, _game.s2d.width, _game.s2d.height);		
		_hud = new Hud(_level, _game.s2d.width, 24);
		add(_view);				
		add(_hud);
		
		#if debug										
		add(_devConsole);
		#end
		
		super.onEnter();
	}
	
	override public function onLeave() {
		// clean up
		_level.removeListener(this);
		_level = null;
		_view.dispose();		
		_view = null;
		_hud = null;
		#if debug
		// make sure console is closed
		if (_devConsole.isActive()) {
			_devConsole.runCommand("");
		}
		#end
		
		super.onLeave();
	}
	
	override public function update(elapsed:Float) {						
		#if debug
		if (_devConsole.isActive()) {
			return;
		}
		#end
		
		// update timed events
		_waiter.update(Timer.tmod);
		// update play
		_level.update(elapsed);
		_view.update(elapsed);		
		_hud.update(elapsed);		
	}
	
	function nextMap() { 
		onLeave(); // FIXME --- that's uggly, do a proper map change :-)
		Gameplay.CURRENT_MAP = (Gameplay.CURRENT_MAP + 1) % Gameplay.MAP_CYCLE.length;
		onEnter(); // FIXME --- that's uggly, do a proper map change :-)
	}
	
	function prevMap() {
		var i = Gameplay.CURRENT_MAP == 0 ? Gameplay.MAP_CYCLE.length - 1 : Gameplay.CURRENT_MAP - 1;		
		onLeave(); // FIXME --- that's uggly, do a proper map change :-)
		Gameplay.CURRENT_MAP = i;
		onEnter(); // FIXME --- that's uggly, do a proper map change :-)		
	}
	
	function restartMap() {
		onLeave(); // FIXME --- that's uggly, do a proper map change :-)
		onEnter(); // FIXME --- that's uggly, do a proper map change :-)				
	}
	
	//// Level listener
	
	public function onTileChanged(tx:Int, ty:Int):Void { /* nothing to do */ }	
	public function onEntitySpawned(e:Entity):Void { /* nothing to do */}	
	public function onEntityRemoved(e:Entity):Void { /* nothing to do */}	
	public function onEntityMoved(e:Entity):Void { /* nothing to do */}
	public function onThemeChanged(newTheme:LevelTheme):Void { /* nothing to do */ }
	public function onExitOpened():Void { /* nothing to do */ }
	
	public function onLevelWon():Void { 
		_waiter.wait(1.0, nextMap);
	}
	
	public function onLifeLost():Void { 
		// TODO restart level if was not last life, game over if last life		
		_waiter.wait(1.0, restartMap);
	}

	//// Dev console	
	#if debug	
	function createDevConsole() {
		_devConsole = new Console(FontBuilder.getFont("consolas", 18), null);				
		_devConsole.addCommand("spawn", "Spawn a new entity at mouse position.", [ { name:"entityType", t:ConsoleArg.AString } ], commandSpawn);
		_devConsole.addAlias("s", "spawn");
		
		_devConsole.addCommand("explode", "Explode entity at mouse position.", [], commandExplode);
		_devConsole.addAlias("x", "explode");
		
		_devConsole.addCommand("dig", "Set empty tile at mouse position.", [], commandDig);
		_devConsole.addAlias("d", "dig");
		
		_devConsole.addCommand("tile", "Change tile at mouse position.", [ { name:"tileType", t:ConsoleArg.AString } ], commandTile);
		_devConsole.addAlias("t", "tile");		
		
		_devConsole.addCommand("open", "Open the exit.", [], commandOpen);
		_devConsole.addAlias("o", "open");			
		
		_devConsole.addCommand("theme", "Change the level theme.", [ { name:"themeName", t:ConsoleArg.AString } ], commandTheme);
		_devConsole.addAlias("th", "theme");				
		
		_devConsole.addCommand("info", "Display level informations and status.", [], commandInfo);
		_devConsole.addAlias("i", "info");						
		
		_devConsole.addCommand("next", "Go to next map.", [], commandNext);
		_devConsole.addAlias("n", "next");						
		
		_devConsole.addCommand("prev", "Go to previous map.", [], commandPrev);
		_devConsole.addAlias("p", "prev");		
	}
	
	inline function getMouseX():Int {
		return Stage.getInstance().mouseX;
	}
	
	inline function getMouseY():Int {
		return Stage.getInstance().mouseY;
	}
	
	inline function screenToTx(x):Int {
		return _view.pixelToTx(x);
	}
	
	inline function screenToTy(y):Int {
		return _view.pixelToTy(y);
	}	
	
	inline function reportCommandError(text:String, ?tx:Int, ?ty:Int) {
		text = "ERROR " + text;
		if (tx != null && ty != null) {
			text += " @[" + tx + "," + ty + "]";
		}		
		_devConsole.log(text, 0xFF0000);
		trace("dev console: "+text);
	}
	
	inline function reportCommandSuccess(text:String, ?tx:Int, ?ty:Int) {
		if (tx != null && ty != null) {
			text += " @[" + tx + "," + ty + "]";
		}
		_devConsole.log(text, 0x00FF00);
		trace("dev console: "+text);
	}	
	
	function commandSpawn(entityType:String) {		
		entityType = entityType.charAt(0).toUpperCase() + entityType.substr(1);
		var cl:Class<Dynamic> = Type.resolveClass("com.rj.boulder.world.entities."+entityType);
		if (cl == null) {
			reportCommandError("unknown entity type " + entityType);
			return;
		}
		
		var tx = screenToTx(getMouseX());
		var ty = screenToTy(getMouseY());		
		if (!_level.isInBounds(tx, ty)) {
			reportCommandError("can't spawn out of bounds", tx, ty);
			return;
		}				
		var other = _level.getEntityAt(tx, ty);
		if (other != null) {
			reportCommandError("another entity " + other + " is already there", tx, ty);
			return;
		}
		
		var e:Entity = Type.createInstance(cl, []);
		_level.spawnEntity(e, tx, ty);		
		reportCommandSuccess("spawned new " + entityType, tx, ty);
	}
	
	function commandExplode() {
		var tx = screenToTx(getMouseX());
		var ty = screenToTx(getMouseY());		
		if (!_level.isInBounds(tx, ty)) {
			reportCommandError("can't explode out of bounds");
			return;
		}				
		var other = _level.getEntityAt(tx, ty);
		if (other == null) {
			reportCommandError("no entity to explode", tx, ty);
			return;
		}
		
		other.explode();		
		reportCommandSuccess("exploded " + other, tx, ty);
	}
	
	function commandDig() {
		var tx = screenToTx(getMouseX());
		var ty = screenToTx(getMouseY());		
		if (!_level.isInBounds(tx, ty)) {
			reportCommandError("can't dig out of bounds");
			return;
		}			
		
		_level.setTile(tx, ty, Tiles.EMPTY);		
		reportCommandSuccess("digged", tx, ty);
	}
	
	function commandTile(tileType:String) {
		var tx = screenToTx(getMouseX());
		var ty = screenToTx(getMouseY());		
		if (!_level.isInBounds(tx, ty)) {
			reportCommandError("can't tile out of bounds");
			return;
		}					
		tileType = tileType.toUpperCase();
		var t:Tiles;
		try {
			t = Tiles.createByName(tileType);
		} catch (ex:String) {
			reportCommandError("unknown tile type " + tileType);
			reportCommandError("tiles : " + Tiles.getConstructors());
			return;
		}
		
		_level.setTile(tx, ty, t);		
		reportCommandSuccess("changed tile to "+tileType, tx, ty);
	}	
	
	function commandOpen() {
		if (_level.isExitOpened) {
			reportCommandError("exit already open.");
			return;
		}
		_level.openExit();
		reportCommandSuccess("Exit opened.");
	}
	
	function commandTheme(themeName:String) {
		themeName = themeName.toUpperCase();
		var t:LevelTheme;
		try {
			t = LevelTheme.createByName(themeName);
		} catch (ex:String) {
			reportCommandError("unknown theme " + themeName);
			reportCommandError("themes : " + LevelTheme.getConstructors());
			return;
		}
		
		_level.theme = t;
		reportCommandSuccess("changed theme to " + themeName);
	}

	function commandInfo() {
		var amoebasTrappedCount, amoebasTotalCount;
		amoebasTrappedCount = amoebasTotalCount = 0;
		for (e in _level.entities) {
			if (Std.is(e, Amoeba)) {
				++amoebasTotalCount;
				if (cast(e, Amoeba).isTrapped) {
					++amoebasTrappedCount;
				}
			}
		}
		
		var info:String = "Level infos : \n";
				
		info += "  diamonds " + _level.diamondsTaken +"/" + _level.diamondsRequired + "\n";
		info += "  amoebas trapped=" + amoebasTrappedCount + " total=" + amoebasTotalCount +"\n";
		
		for (line in info.split("\n")) {
			reportCommandSuccess(line);
		}
	}
	
	function commandNext() {
		nextMap();
		reportCommandSuccess("next map started");
	}
	
	function commandPrev() {
		prevMap();
		reportCommandSuccess("previous map started");
		
	}
	#end

}