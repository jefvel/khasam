package com.jefvel.sam;
import haxe.ds.Vector;


/**
 * ...
 * @author jefvel
 */
class SamData
{

	public var mem39:Int;
	public var mem44:Int;
	public var mem47:Int;
	public var mem49:Int;
	public var mem50:Int;
	public var mem51:Int;
	public var mem53:Int;
	public var mem56:Int;
	
	public var X:Int;
	public var Y:Int;
	public var A:Int;
	
	public var speed:Int;
	public var pitch:Int;
	public var singMode:Bool;
	
	public var phonemeIndexOutput:Vector<Int>;
	public var stressOutput:Vector<Int>;
	public var phonemeLengthOutput:Vector<Int>;	
	
	public var stress:Vector<Int>;
	public var phonemeLength:Vector<Int>;
	public var phonemeIndex:Vector<Int>;
		
	public function new() {
		singMode = false;
		
		phonemeIndexOutput = new Vector<Int>(60);
		stressOutput = new Vector<Int>(60);
		phonemeLengthOutput = new Vector<Int>(60);
		
		stress = new Vector<Int>(256);
		phonemeLength = new Vector<Int>(256);
		phonemeIndex = new Vector<Int>(256);
	}
}