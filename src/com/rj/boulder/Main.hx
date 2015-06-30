package com.rj.boulder;

import com.rj.boulder.render.GameSprites;
import com.rj.boulder.screens.MenuScreen;
import com.rj.boulder.screens.PlayScreen;
import com.rj.heaps.SfxPlayer;
import flash.net.FileReference;
import hxd.App;
import hxd.BitmapData;
import hxd.Key;
import hxd.Res;
import hxd.Timer;

/**
 * @author roguedjack
 */
class Main extends App {
	static public inline var GAME_WIDTH:Int = 640;
	static public inline var GAME_HEIGHT:Int = 480;	
	
	public var menuScreen(default, null):Screen;
	public var playScreen(default, null):Screen;
	private var _screen:Screen;	
	
	override function init() {
		s2d.setFixedSize(GAME_WIDTH, GAME_HEIGHT);
		
		GameSprites.init();
		
		menuScreen = new MenuScreen(this);
		playScreen = new PlayScreen(this);
		
		switchScreen(menuScreen);
	}
	
	override function update(dt:Float) {
		#if debug
		if (Key.isPressed(Key.F1)) {
			var bmp = new BitmapData(GAME_WIDTH, GAME_HEIGHT);
			engine.setCapture(bmp, function():Void {
				var png = bmp.toPNG();
				var file = new FileReference();
				file.save(png.getData(), "screenshot.png");
				bmp.dispose();
			});
		}
		#end
		
		var elapsed:Float = Timer.deltaT;
		SfxPlayer.tick(elapsed);		
		if (_screen != null) {
			_screen.update(elapsed);
		}
	}
	
	public function switchScreen(s:Screen) {
		if (_screen != null) {
			_screen.onLeave();
		}
		_screen = s;
		if (s != null) {
			s.onEnter();
		}
	}
	
	static function main() {
		Res.initEmbed();
		Key.initialize();
		new Main();
	}
}