package com.rj.boulder.screens;

import com.rj.boulder.Main;
import com.rj.boulder.Screen;
import com.rj.boulder.world.Gameplay;
import h2d.Font;
import h2d.Sprite;
import h2d.Text;
import hxd.Key;
import hxd.res.FontBuilder;

/**
 * ...
 * @author roguedjack
 */
class MenuScreen extends Screen {
	private var _font:Font;
	private var _title:Text;

	public function new(game:Main) {
		super(game);
		
		_font = FontBuilder.getFont("consolas", 16);
		_title = new Text(_font);
		_title.text = "BOULDER FLASH\nSPACE to start\nWASD or cursor to move\nSPACE to push/pickup\nESC to suicide :-]";
		_title.text += "\nThere's no life and scoring, you can play as long as you want.";
		#if debug
		_title.text += "\n\nDEV DEBUG :\n / to show console; type help to list commands\nF1 to capture png screenshot";
		#end
		_title.textColor = 0xFF0000;
	}
	
	override public function onEnter() {
		add(_title);
		
		super.onEnter();
	}
	
	override function remove(s:Sprite) {
		remove(_title);
		
		super.remove(s);
	}
	
	override public function update(elapsed:Float) {
		if (Key.isDown(Key.SPACE)) {
			Gameplay.newGame();
			_game.switchScreen(_game.playScreen);
		}
	}
}