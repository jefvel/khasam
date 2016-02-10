package com.jefvel.sam;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Int32Array;
import kha.audio1.Audio;

/**
 * ...
 * @author jefvel
 */
class Sam
{

	var input:String;
	var speed:Int = 72;
	var pitch:Int = 64;
	var mouth:Int = 128;
	var throat:Int = 128;
	var singMode:Bool = false;
	
	var mem39:Int;
	var mem44:Int;
	var mem47:Int;
	var mem49:Int;
	var mem50:Int;
	var mem51:Int;
	var mem56:Int;
	
	var mem59:Int = 0;
	
	var A:Int;
	var X:Int;
	var Y:Int;
	
	var stress:Vector<Int>;
	var phonemeLength:Vector<Int>;
	var phonemeIndex:Vector<Int>;
	
	var phonemeIndexOutput:Vector<Int>;
	var stressOutput:Vector<Int>;
	var phonemeLengthOutput:Vector<Int>;
	
	var o:SamTabs;
	var p:ReciterTabs;
	var i:RenderTabs;
	
	var render:SamRender;
	var reciter:SamReciter;
	
	public static var bufferPos = 0;
	public static var buffer:Vector<Int> = new Vector<Int>(44100 * 10);
	
	public function new() 
	{
		stress = new Vector<Int>(256);
		phonemeLength = new Vector<Int>(256);
		phonemeIndex = new Vector<Int>(256);
		
		phonemeIndexOutput = new Vector<Int>(60);
		stressOutput = new Vector<Int>(60);
		phonemeLengthOutput = new Vector<Int>(60);
		
		render = new SamRender();
		
		var o = SamReciter.textToPhonemes("what is good[");
		var res = "";
		for (i in SamReciter.result) {
			res += String.fromCharCode(i);
		}
		
		trace(res);
		//trace(o);
	}
	
	function init() {
		
	}
	
	public function setInput(input:String):Void {
		
	}
	
	public function setSpeed(speed:Int):Void {
		
	}
	
	public function setPitch(pitch:Int):Void {
		
	}
	
	public function setMouth(mouth:Int):Void {
		
	}
	
	public function setThroat(mouth:Int):Void {
		
	}
	
	public function enableSingMode():Void {
		
	}
	
	public function getBuffer():SamSound {
		var length = 44100*10;
		var data:Vector<Float> = new Vector<Float>(length);
		for (i in 0...length) {
			//data[i] =  (Math.sin((i / (300.0 + Math.sin(i * 0.001) * 99))) * 0.5 + 0.5) / Math.pow(i * 0.0001, 3) ;
		}
		
		return new SamSound(data);
	}
}