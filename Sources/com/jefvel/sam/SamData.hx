package com.jefvel.sam;
import haxe.ds.Vector;


/**
 * ...
 * @author jefvel
 */
class SamData
{

	public var mem39:Int = 0;
	public var mem44:Int = 0;
	public var mem47:Int = 0;
	public var mem49:Int = 0;
	public var mem50:Int = 0;
	public var mem51:Int = 0;
	public var mem53:Int = 0;
	public var mem56:Int = 0;
	
	public var X:Int;
	public var Y:Int;
	public var A:Int;
	
	public var speed:Int = 72;
	public var pitch:Int = 64;
	public var mouth:Int = 128;
	public var throat:Int = 128;
	
	public var singMode:Bool = false;
	
	public var phonemeIndexOutput:Vector<Int>;
	public var stressOutput:Vector<Int>;
	public var phonemeLengthOutput:Vector<Int>;	
	
	public var stress:Vector<Int>;
	public var phonemeLength:Vector<Int>;
	public var phonemeIndex:Vector<Int>;
		
	public function new() {
		phonemeIndexOutput = new Vector<Int>(60);
		stressOutput = new Vector<Int>(60);
		phonemeLengthOutput = new Vector<Int>(60);
		
		stress = new Vector<Int>(256);
		phonemeLength = new Vector<Int>(256);
		phonemeIndex = new Vector<Int>(256);
	}
	
	public function reset() {
		mem39 = mem44 = mem47 = mem49 = mem50 = mem51 = mem53 = mem56 = 0;
		//singMode = false;
		for (i in 0...60) {
			phonemeIndexOutput[i] = 0;
			stressOutput[i] = 0;
			phonemeLengthOutput[i] = 0;
		}
		
		for (i in 0...256) {
			phonemeIndex[i] = 0;
			phonemeLength[i] = 0;
			stress[i] = 0;
		}
	}
}