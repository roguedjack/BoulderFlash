package com.rj.boulder.render;

import com.rj.boulder.world.entities.Player;
import com.rj.boulder.world.Level;
import h2d.Bitmap;
import h2d.Font;
import h2d.Sprite;
import h2d.Text;
import h2d.Tile;
import hxd.res.FontBuilder;
import hxd.Timer;

/**
 * ...
 * @author roguedjack
 */
class Hud extends Sprite {
	
	private var _level:Level;	
	private var _info:Text;

	public function new(level:Level, widthPixels:Int, heightPixels:Int) {
		super();
		_level = level;		
		
		var bg:Bitmap = new Bitmap();
		bg.tile = Tile.fromColor(0x000000, 1, 1, 0.25);
		bg.scaleX = widthPixels;
		bg.scaleY = heightPixels;
		
		var font:Font = FontBuilder.getFont("consolas", 20);
		_info = new Text(font);
		_info.textColor = 0xFFFFFF;
		
		addChild(bg);
		addChild(_info);
	}
	
	public function update(elapsed:Float) {
		refresh();
	}
	
	public function refresh() {
		var s;
		
		function padZeroes(i, digits:Int):String {
			return StringTools.lpad("" + Std.int(i), "0", digits);
		}

		// level name
		s = " " + _level.name;		
		// diamonds 
		s += " " + padZeroes(_level.diamondsTaken, 2) + "/" + padZeroes(_level.diamondsRequired, 2);		
		// "get ready" or timer
		if (_level.player != null && _level.player.state == PlayerState.WAITING_TO_SPAWN) {
			s += " GET READY!";
		} else {
			s += " " + padZeroes(_level.timeLeft, 3);
		}
		// TODO --- lives		
		// TODO --- score

		
		#if debug		
		s += " || fps" + Std.int(Timer.fps() * 10) / 10;
		#end
		
		_info.text = s;
	}
}