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
class SamRender
{

	var input:String;
	var speed:Int;
	var pitch:Int;
	var mouth:Int = 128;
	var throat:Int = 128;
	var singMode:Bool = false;
	
	var wait1:Int = 7;
	var wait2:Int = 6;
	
	var mem39:Int;
	var mem44:Int;
	var mem47:Int;
	var mem49:Int;
	var mem50:Int;
	var mem51:Int;
	var mem53:Int;
	var mem56:Int;
	
	var mem59:Int = 0;
	
	var A:Int;
	var X:Int;
	var Y:Int;
	
	var stress:Vector<Int>;
	var phonemeLength:Vector<Int>;
	var phonemeIndex:Vector<Int>;
	
	var pitches:Vector<Int>;
	
	var frequency1:Vector<Int>;
	var frequency2:Vector<Int>;
	var frequency3:Vector<Int>;
	
	var amplitude1:Vector<Int>;
	var amplitude2:Vector<Int>;
	var amplitude3:Vector<Int>;
	
	var sampledConsonantFlag:Vector<Int>;

	var phonemeIndexOutput:Vector<Int>;
	var stressOutput:Vector<Int>;
	var phonemeLengthOutput:Vector<Int>;
	
	var o:SamTabs;
	var p:ReciterTabs;
	var i:RenderTabs;
	
	public static var timetable =
	[
		[162, 167, 167, 127, 128],
		[226, 60, 60, 0, 0],
		[225, 60, 59, 0, 0],
		[200, 0, 0, 54, 55],
		[199, 0, 0, 54, 54]
	];

	
	public function new() 
	{
		pitches = new Vector<Int>(256);
		
		frequency1 = new Vector<Int>(256);
		frequency2 = new Vector<Int>(256);
		frequency3 = new Vector<Int>(256);
		
		amplitude1 = new Vector<Int>(256);
		amplitude2 = new Vector<Int>(256);
		amplitude3 = new Vector<Int>(256);
		
		sampledConsonantFlag = new Vector<Int>(256);
		
		stress = new Vector<Int>(256);
		phonemeLength = new Vector<Int>(256);
		phonemeIndex = new Vector<Int>(256);
		
		phonemeIndexOutput = new Vector<Int>(60);
		stressOutput = new Vector<Int>(60);
		phonemeLengthOutput = new Vector<Int>(60);
	}
	
	static var oldtimetableindex = 0;
	function output(index:Int, A:Int):Void {
		var k = 0;
		Sam.bufferPos += timetable[oldtimetableindex][index];
		oldtimetableindex = index;
		// write a little bit in advance
		for(k in 0...5) {
			Sam.buffer[Std.int(Sam.bufferPos / 50 + k)] = (A & 15) * 16;
		}
	}

	function read(p:Int, Y:Int):Int	{
		switch(p) {
			case 168: return pitches[Y];
			case 169: return frequency1[Y];
			case 170: return frequency2[Y];
			case 171: return frequency3[Y];
			case 172: return amplitude1[Y];
			case 173: return amplitude2[Y];
			case 174: return amplitude3[Y];
		}
		
		return 0;
	}
	
	function write(p:Int, Y:Int, value:Int) {
		switch(p){
			case 168: pitches[Y] = value; return;
			case 169: frequency1[Y] = value;  return;
			case 170: frequency2[Y] = value;  return;
			case 171: frequency3[Y] = value;  return;
			case 172: amplitude1[Y] = value;  return;
			case 173: amplitude2[Y] = value;  return;
			case 174: amplitude3[Y] = value;  return;
		}
	}
	
	function renderSample(mem66:Array<Int>, pos:Int) {     
		var tempA:Int;
		var phase1:Int;
		
		// current phoneme's index
		mem49 = Y;

		// mask low three bits and subtract 1 get value to 
		// convert 0 bits on unvoiced samples.
		A = mem39&7;
		X = A-1;

		// store the result
		mem56 = X;
		
		// determine which offset to use from table { 0x18, 0x1A, 0x17, 0x17, 0x17 }
		// T, S, Z                0          0x18
		// CH, J, SH, ZH          1          0x1A
		// P, F*, V, TH, DH       2          0x17
		// /H                     3          0x17
		// /X                     4          0x17

		// get value from the table
		mem53 = RenderTabs.tab48426[X];
		mem47 = X;      //46016+mem[56]*256
		
		// voiced sample?
		A = mem39 & 248;
		if(A == 0) {
			// voiced phoneme: Z*, ZH, V*, DH
			Y = mem49;
			A = pitches[mem49] >> 4;
		} else {
		
			Y = A ^ 255;
			var skipFirst = false;
			while(true){
				if(!skipFirst) {
					// step through the 8 bits in the sample
					mem56 = 8;
					
					// get the next sample from the table
					// mem47*256 = offset to start of samples
					A = RenderTabs.sampleTable[mem47 * 256 + Y];
					
				}
				
				skipFirst = false;

				// left shift to get the high bit
				tempA = A;
				A = A << 1;
				//48281: BCC 48290
				
				// bit not set?
				if ((tempA & 128) == 0) {
					// convert the bit to value from table
					X = mem53;
					//mem[54296] = X;
					// output the byte
					output(1, X);
				}
				
				if (X != 0 && (tempA & 128) == 0) {
					
				}else{
					// output a 5 for the on bit
					output(2, 5);
				}

				X = 0;

				// decrement counter
				mem56--;
				
				// if not done, jump to top of loop
				if (mem56 != 0) {
					skipFirst = true;
					continue;
				}
				
				// increment position
				Y++;
				if (Y != 0) {
					skipFirst = false;
					continue;
				}
				
				// restore values and return
				mem44 = 1;
				Y = mem49;
				
				return;
			}
		}
		
		// handle voiced samples here
		// number of samples?
		phase1 = A ^ 255;

		Y = mem66[pos];
		
		do {
			//pos48321:

			// shift through all 8 bits
			mem56 = 8;
			//A = Read(mem47, Y);
			
			// fetch value from table
			A = RenderTabs.sampleTable[mem47*256+Y];

			// loop 8 times
			//pos48327:
			do {
				//48327: ASL A
				//48328: BCC 48337
				
				// left shift and check high bit
				tempA = A;
				A = A << 1;
				if ((tempA & 128) != 0) {
					// if bit set, output 26
					X = 26;
					output(3, X);
				} else {
					//timetable 4
					// bit is not set, output a 6
					X=6;
					output(4, X);
				}

				mem56--;
				
			} while(mem56 != 0);

			// move ahead in the table
			Y++;
			
			// continue until counter done
			phase1++;

		} while (phase1 != 0);
		//	if (phase1 != 0) goto pos48321;
		
		// restore values and return
		A = 1;
		mem44 = 1;
		mem66[pos] = Y;
		Y = mem49;
		
		return;
	}

	
	

	function AddInflection(mem48:Int, phase1:Int)
	{
		//pos48372:
		//	mem48 = 255;
		//pos48376:
			   
		// store the location of the punctuation
		mem49 = X;
		A = X;
		var Atemp = A;
		
		// backup 30 frames
		A = A - 30; 
		// if index is before buffer, point to start of buffer
		if (Atemp <= 30) {
			A = 0;
		}
		X = A;

		// FIXME: Explain this fix better, it's not obvious
		// ML : A =, fixes a problem with invalid pitch with '.'
		while ( (A = pitches[X]) == 127) {
			X++;
		}
		var first = true;
		while(true){
			if (first || pitches[X] == 255) 
			{
				//48398: CLC
				//48399: ADC 48
				
				// add the inflection direction
				A += mem48;
				phase1 = A;
				
				// set the inflection
				pitches[X] = A;
			}
			
			first = false;
				
			// increment the position
			X++;
			
			// exit if the punctuation has been reached
			if (X == mem49) {
				return; //goto pos47615;
			}
			
			if (pitches[X] != 255) {
				A = phase1;
			}
		}
	}
	
	
	function trans(mem39212:Int, mem39213:Int):Int {
		//pos39008:
		var carry:Int;
		var temp:Int;
		var mem39214:Int;
		var mem39215:Int;
		A = 0;
		mem39215 = 0;
		mem39214 = 0;
		X = 8;
		do {
			carry = mem39212 & 1;
			mem39212 = mem39212 >> 1;
			if (carry != 0) {
				carry = 0;
				A = mem39215;
				temp = A + mem39213;
				A = A + mem39213;
				if (temp > 255) {
					carry = 1;
				}
				mem39215 = A;
			}
			temp = mem39215 & 1;
			mem39215 = (mem39215 >> 1) | ((carry != 0)?128:0);
			carry = temp;
			X--;
		} while (X != 0);
		
		temp = mem39214 & 128;
		mem39214 = (mem39214 << 1) | ((carry != 0)?1:0);
		carry = temp;
		temp = mem39215 & 128;
		mem39215 = (mem39215 << 1) | ((carry != 0)?1:0);
		carry = temp;

		return mem39215;
	}
	
	public function setMouthThroat(mouth:Int, throat:Int) {
		var initialFrequency = 0;
		var newFrequency = 0;

		// mouth formants (F1) 5..29
		var mouthFormants5_29 = [
			0, 0, 0, 0, 0, 10,
			14, 19, 24, 27, 23, 21, 16, 20, 14, 18, 14, 18, 18,
			16, 13, 15, 11, 18, 14, 11, 9, 6, 6, 6];

		// throat formants (F2) 5..29
		var throatFormants5_29 = [
		255, 255,
		255, 255, 255, 84, 73, 67, 63, 40, 44, 31, 37, 45, 73, 49,
		36, 30, 51, 37, 29, 69, 24, 50, 30, 24, 83, 46, 54, 86 ];

		var mouthFormants48_53 = [19, 27, 21, 27, 18, 13];

		var throatFormants48_53 = [72, 39, 31, 43, 30, 34];

		var pos = 5;
		while(pos != 30) {
			// recalculate mouth frequency
			initialFrequency = mouthFormants5_29[pos];
			if (initialFrequency != 0) newFrequency = trans(mouth, initialFrequency);
			RenderTabs.freq1data[pos] = newFrequency;
				   
			// recalculate throat frequency
			initialFrequency = throatFormants5_29[pos];
			if(initialFrequency != 0) newFrequency = trans(throat, initialFrequency);
			RenderTabs.freq2data[pos] = newFrequency;
			pos++;
		}

		pos = 48;
		Y = 0;
		while(pos != 54) {
			// recalculate F1 (mouth formant)
			initialFrequency = mouthFormants48_53[Y];
			newFrequency = trans(mouth, initialFrequency);
			RenderTabs.freq1data[pos] = newFrequency;
			   
			// recalculate F2 (throat formant)
			initialFrequency = throatFormants48_53[Y];
			newFrequency = trans(throat, initialFrequency);
			RenderTabs.freq2data[pos] = newFrequency;
			Y++;
			pos++;
		}	
	}
	
	public function getBuffer():SamSound {
		var length = 44100*10;
		var data:Vector<Float> = new Vector<Float>(length);
		for (i in 0...length) {
			data[i] =  Math.sin((i / 32.0) * Math.PI) * 0.5 + 0.5;
		}
		
		return new SamSound(data);
	}
}