package com.rj.heaps;
import hxd.Key;

/**
 * Missing letter keys from hxd.Key and various helpers.
 * 
 * @author roguedjack
 */
class Keys {
	
	static public inline var A = Key.A;
	static public inline var B = Key.A+1;
	static public inline var C = Key.A+2;
	static public inline var D = Key.A+3;
	static public inline var E = Key.A+4;
	static public inline var F = Key.A+5;
	static public inline var G = Key.A+6;
	static public inline var H = Key.A+7;
	static public inline var I = Key.A+8;
	static public inline var J = Key.A+9;
	static public inline var K = Key.A+10;
	static public inline var L = Key.A+11;
	static public inline var M = Key.A+12;
	static public inline var N = Key.A+13;
	static public inline var O = Key.A+14;
	static public inline var P = Key.A+15;
	static public inline var Q = Key.A+16;
	static public inline var R = Key.A+17;
	static public inline var S = Key.A+18;
	static public inline var T = Key.A+19;
	static public inline var U = Key.A+20;
	static public inline var V = Key.A+21;
	static public inline var W = Key.A+22;
	static public inline var X = Key.A+23;
	static public inline var Y = Key.A+24;
	static public inline var Z = Key.A + 25;
	
	static public function anyKeyDown(keys:Array<Int>):Bool {
		for (k in keys) {
			if (Key.isDown(k)) {
				return true;
			}
		}
		return false;		
	}

	private function new() { }
	
}