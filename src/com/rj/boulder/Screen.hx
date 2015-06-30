package com.rj.boulder;
import h2d.Sprite;

/**
 * ...
 * @author roguedjack
 */
class Screen {
	private var _game:Main;
	private var _root:Sprite;

	private function new(game:Main) {
		_game = game;
		_root = new Sprite();
	}
	
	public function onEnter() { 
		_game.s2d.addChild(_root);
	}
	
	public function onLeave() { 
		// clear root
		while (_root.numChildren > 0) {
			_root.getChildAt(0).remove();
		}
		
		_game.s2d.removeChild(_root);		
	}
	
	private function add(s:Sprite) {
		_root.addChild(s);		
	}
	
	private function remove(s:Sprite) {
		_root.removeChild(s);
	}
	
	public function update(elapsed:Float) {}	
}