package com.rj.heaps;

import hxd.res.TiledMap;
	
/**
 * ...
 * @author roguedjack
 */
class TiledMapExtenders {
	
	static public function readProperties(map:TiledMap):Map<String,String> {		
		var data = map.entry.getBytes().toString();
		var base = new haxe.crypto.BaseCode(haxe.io.Bytes.ofString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"));
		var root = new haxe.xml.Fast(Xml.parse(data).firstElement());
		
		var props = new Map<String,String>();
		// iterate to find the properties, 
		// doing it the fast xml way iterating on "root.nodes.property.nodes.property" refuses to compile.
		for (node in root.elements) {
			if (node.name == "properties") {
				for (xprop in node.nodes.property) {
					// trace("prop " + xprop.att.name+" = " +xprop.att.value);
					props.set(xprop.att.name, xprop.att.value);
				}
			}
		}
		return props;
	}

	private function new() { }
	
}