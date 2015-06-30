package com.rj.boulder.render;

import com.rj.boulder.world.Entity;
import com.rj.boulder.world.Gameplay;
import com.rj.boulder.world.Level;
import com.rj.boulder.world.Tiles;
import com.rj.heaps.SfxPlayer;
import h2d.Bitmap;
import h2d.col.Bounds;
import h2d.col.Point;
import h2d.filter.ColorMatrix;
import h2d.RenderContext;
import h2d.Sprite;
import h2d.Tile;
import hxd.Key;
import hxd.Res;

/**
 * ...
 * @author roguedjack
 */
class LevelView extends Sprite implements LevelListener {
	private var _level:Level;
	private var _dirtyTiles:Array<Int>;
	private var _tilesBitmaps:Array<Bitmap>;
	private var _levelRoot:Sprite;
	private var _tilesLayer:Sprite;
	private var _entitiesLayer:Sprite;	
	private var _viewBounds:Bounds;  // view bounds in map coordinates not pixels!
	private var _viewTarget:Point;
	private var _flashLayer:Bitmap;
	private var _flashDuration:Float;
	private var _flashTimer:Float;
	private var _showFlash:Bool;

	public function new(level:Level, widthPixels:Int, heightPixels:Int) {
		super();		
		_level = level;
		_dirtyTiles = [];				

		_flashLayer = new Bitmap(Tile.fromColor(Gameplay.LEVEL_WIN_FLASH_COLOR), this);
		_flashLayer.scaleX = widthPixels;
		_flashLayer.scaleY = heightPixels;
		_flashLayer.visible = false;
		_levelRoot = new Sprite(this);
		_tilesLayer = new Sprite(_levelRoot);
		_entitiesLayer = new Sprite(_levelRoot);
	
		function createTileBitmap(tx:Int, ty:Int):Bitmap {
			var bmp = new Bitmap(null, _tilesLayer);
			bmp.setPos(tx * GameSprites.SPRITE_SIZE, ty * GameSprites.SPRITE_SIZE);
			return bmp;
		}			
		_tilesBitmaps = [for (ty in 0...level.height) for (tx in 0...level.width) createTileBitmap(tx, ty)];
		redrawAllTiles();				
		onThemeChanged(_level.theme);
		
		for (e in _level.entities) {
			_entitiesLayer.addChild(e.anim);
		}
		
		_viewBounds = Bounds.fromValues(0, 0, Std.int(widthPixels / GameSprites.SPRITE_SIZE), Std.int(heightPixels / GameSprites.SPRITE_SIZE));
		_viewTarget = new Point();
		setViewOn(_level.player);
		
		_level.addListener(this);		
	}

	private inline function colorMatrixFromTheme(t:LevelTheme):ColorMatrix {
		var hue:Float = switch (t) {
			// correct values found by testing :-]
			case LevelTheme.DEFAULT: 0;
			case LevelTheme.BLUE: 180.0;
			case LevelTheme.GREEN: 120.0;
			case LevelTheme.RED: 290.0;
			default: throw "unhandled level theme color";
		};
		var m = new ColorMatrix();		
		m.matrix.identity();
		m.matrix.colorHue(hue * Math.PI / 180.0);
		return m;
	}
	
	//var TEST_hue:Float = 0;
	public function update(elapsed:Float) {
		// flash effect
		if (_showFlash) {
			if (_flashDuration > 0) {
				_flashDuration -= elapsed;
				_flashTimer -= elapsed;
				if (_flashTimer < 0) {
					_flashLayer.visible = !_flashLayer.visible;						
					_flashTimer += Gameplay.LEVEL_WIN_FLASH_PERIOD;								
				}
			} else {
				_showFlash = false;
				_flashLayer.visible = false;
			}
		}
		
		// scroll view to keep it around the player
		follow(_level.player);
		
		// TEST: find the hues
		/*
		var modHue:Float = 0;
		if (Key.isPressed(Key.NUMPAD_ADD)) {
			modHue = 0.1;
		} else if (Key.isPressed(Key.NUMPAD_SUB)) {
			modHue -= 0.1;
		}
		if (modHue != 0) {
			TEST_hue += modHue;
			trace("new hue = " + TEST_hue);
			trace("in degs = " + TEST_hue * 180.0 / Math.PI);
			var m = cast(filters[0], ColorMatrix);
			m.matrix.identity();
			m.matrix.colorHue(TEST_hue);
		}
		*/
	}
	
	public function dispose() {
		_level.removeListener(this);
	}

	//// Drawing
	
	override function draw(ctx:RenderContext) {
		// redraw dirty tiles
		if (_dirtyTiles.length > 0) {
			redrawDirtyTiles();
			_dirtyTiles = [];
		}
		
		super.draw(ctx);
	}
	
	function redrawAllTiles() {
		for (ty in 0..._level.height) {
			for (tx in 0..._level.width) {
				redrawTile(tx, ty);
			}
		}
	}
	
	function redrawDirtyTiles() {
		for (i in _dirtyTiles) {
			redrawTile(i % _level.width, Std.int(i / _level.width));
		}
	}
	
	function redrawTile(tx:Int, ty:Int) {
		//trace("redrawTile " + tx + "," + ty);
		
		var img:Tile;
		
		switch (_level.getTile(tx, ty)) {
			case Tiles.BARRIER:
				img = GameSprites.at(1, 6);
			case Tiles.EARTH:
				img = GameSprites.at(1, 7);
			case Tiles.EMPTY:
				img = null;				
			case Tiles.WALL:
				img = GameSprites.at(3, 6);
			default:
				throw "unhandled tile";
		}
		
		var bmp = _tilesBitmaps[ty * _level.width + tx];
		if (img == null) {
			bmp.visible = false;
		} else {
			bmp.tile = img;
			bmp.visible = true;
		}
	}

	//// View camera
	
	function setViewTarget(tx:Int, ty:Int) {		
		_viewTarget.x = tx - Gameplay.VIEW_SCROLL_XFOCUS;
		_viewTarget.y = ty - Gameplay.VIEW_SCROLL_YFOCUS;
		if (_viewTarget.x < 0) _viewTarget.x = 0;
		if (_viewTarget.y < 0) _viewTarget.y = 0;
		if (_viewTarget.x + _viewBounds.width >= _level.width) _viewTarget.x = _level.width - _viewBounds.width;
		if (_viewTarget.y + _viewBounds.height >= _level.height) _viewTarget.y = _level.height - _viewBounds.height;		
	}
	
	function setViewPos(x:Float, y:Float) {
		_viewBounds.x = x;
		_viewBounds.y = y;
	}
	
	function setViewOn(e:Entity) {
		if (e == null) {
			return;
		}
	
		setViewTarget(e.tx, e.ty);
		setViewPos(_viewTarget.x, _viewTarget.y);
		refreshLayersPosition();
	}
	
	function follow(e:Entity) {		
		if (e == null) {
			return;
		}
		
		setViewTarget(e.tx, e.ty);
		
		// see if we need to scroll the view to the target pos
		var scrolled = false;
		if (_viewTarget.x < _viewBounds.x) {
			_viewBounds.x = Math.max(_viewBounds.x - Gameplay.VIEW_SCROLL_STEP, _viewTarget.x);
			scrolled = true;
		}  else if (_viewTarget.x > _viewBounds.x) {
			_viewBounds.x = Math.min(_viewBounds.x + Gameplay.VIEW_SCROLL_STEP, _viewTarget.x); 
			scrolled = true;
		}
		if (_viewTarget.y < _viewBounds.y) {
			_viewBounds.y = Math.max(_viewBounds.y - Gameplay.VIEW_SCROLL_STEP, _viewTarget.y);
			scrolled = true;
		}  else if (_viewTarget.y > _viewBounds.y) {
			_viewBounds.y = Math.min(_viewBounds.y + Gameplay.VIEW_SCROLL_STEP, _viewTarget.y); 
			scrolled = true;
		}		
		if (scrolled) {
			refreshLayersPosition();
		}
	}	
	
	function refreshLayersPosition() {
		_levelRoot.setPos(-_viewBounds.x * GameSprites.SPRITE_SIZE, -_viewBounds.y * GameSprites.SPRITE_SIZE);
	}
	
	public function pixelToTx(x:Float):Int {
		return Math.floor(x / GameSprites.SPRITE_SIZE + _viewBounds.x);
	}
	
	public function pixelToTy(y:Float):Int {
		return Math.floor(y / GameSprites.SPRITE_SIZE + _viewBounds.y);
	}			

	//// Flash effect
	
	public function flash() {
		_flashDuration = Gameplay.LEVEL_WIN_FLASH_DURATION;
		_flashTimer = Gameplay.LEVEL_WIN_FLASH_PERIOD;
		_showFlash = true;
	}
	
	//// Level listener
		
	public function onTileChanged(tx:Int, ty:Int):Void {
		_dirtyTiles.push(ty * _level.width + tx);
	}
	
	public function onEntitySpawned(e:Entity):Void {		
		_entitiesLayer.addChild(e.anim);
	}
	
	public function onEntityRemoved(e:Entity):Void {		
		_entitiesLayer.removeChild(e.anim);
	}
	
	public function onEntityMoved(e:Entity):Void { /* nothing to do */ }

	public function onThemeChanged(newTheme:LevelTheme):Void {		
		var f = colorMatrixFromTheme(newTheme);
		if (filters.length == 0) {
			filters.push(f);
		} else {
			filters[0] = f;
		}
	}	
	
	public function onExitOpened():Void {
		flash();
	}

	public function onLevelWon():Void { 
		SfxPlayer.play(Res.sfx.level_won);
		flash();
	}
	
	public function onLifeLost():Void {  /* nothing to do */ }
}
	
	