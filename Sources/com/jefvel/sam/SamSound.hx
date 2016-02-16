package com.jefvel.sam;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Int32Array;
import kha.audio2.Audio;
import kha.audio2.Audio1;
import kha.Sound;

/**
 * ...
 * @author jefvel
 */
class SamSound
{	
	
	var sound:Sound;
	public function new(data:Vector<Float>) 
	{
		sound = new Sound();
		sound.data = data;
	}
	
	public function play() {
		return Audio1.play(sound);
	}
}