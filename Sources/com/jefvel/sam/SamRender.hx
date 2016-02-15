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
class SamRender {

	var input:String;
	var mouth:Int = 128;
	var throat:Int = 128;
	
	var wait1:Int = 7;
	var wait2:Int = 6;
	
	var A:Int;
	var X:Int;
	var Y:Int;
	
	var pitches:Vector<Int>;
	
	var frequency1:Vector<Int>;
	var frequency2:Vector<Int>;
	var frequency3:Vector<Int>;
	
	var amplitude1:Vector<Int>;
	var amplitude2:Vector<Int>;
	var amplitude3:Vector<Int>;
	
	var sampledConsonantFlag:Vector<Int>;

	var d:SamData;
	
	public static var timetable = [
		[162, 167, 167, 127, 128],
		[226, 60, 60, 0, 0],
		[225, 60, 59, 0, 0],
		[200, 0, 0, 54, 55],
		[199, 0, 0, 54, 54]
	];

	var currentJump = 1;
	function log(str:String) {
		//trace("Jmp: " + currentJump + ": " + str);
		currentJump++;
	}

	public function new() {
		//trace("L:" + RenderTabs.sampleTable.length);
		pitches = new Vector<Int>(256);
		for (i in 0...256) {
			pitches[i] = 0;
		}
		
		frequency1 = new Vector<Int>(256);
		frequency2 = new Vector<Int>(256);
		frequency3 = new Vector<Int>(256);
		
		amplitude1 = new Vector<Int>(256);
		amplitude2 = new Vector<Int>(256);
		amplitude3 = new Vector<Int>(256);
		
		sampledConsonantFlag = new Vector<Int>(256);
	}
	
	static var oldtimetableindex = 0;
	function Output(index:Int, A:Int):Void {
		Sam.bufferPos += timetable[oldtimetableindex][index];
		oldtimetableindex = index;
		// write a little bit in advance		
		for(k in 0...5) {
			Sam.buffer[Std.int(Sam.bufferPos / 50 + k)] = (A & 15) * 16;
		}
		//trace(Sam.bufferPos);
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
		
	public function PrepareOutput(d:SamData):Void {
		this.d = d;
		
		A = 0;
		X = 0;
		Y = 0;
		
		//trace(d);
		
		var runs = 0;
		
		//pos48551:
		while (runs < 10000) {
			runs++;
			A = d.phonemeIndex[X];
			if (A == 255) {
				A = 255;
				d.phonemeIndexOutput[Y] = 255;
				Render();
				return;
			}
			
			if (A == 254) {
				X++;
				X = X % 256;
				var temp = X;
				//mem[48546] = X;
				d.phonemeIndexOutput[Y] = 255;
				//Render();
				//X = mem[48546];
				X = temp;
				Y = 0;
				continue;
			}

			if (A == 0) {
				X++;
				X = X % 256;
				continue;
			}

			d.phonemeIndexOutput[Y] = A;
			d.phonemeLengthOutput[Y] = d.phonemeLength[X];
			d.stressOutput[Y] = d.stress[X];
			X++;
			X = X % 256;
			Y++;
			Y = Y % 256;
		}
		//trace(runs + ", " + A);
		//trace("X:" + X);
	}
	
	function RenderSample(mem66:Int):Int //unsigned char *
	{     
		var tempA:Int; // Omt
		// current phoneme's index
		d.mem49 = Y;

		// mask low three bits and subtract 1 get value to 
		// convert 0 bits on unvoiced samples.
		A = d.mem39&7;
		X = A - 1;
		if (X < 0) {
			X += 256;
		}

		// store the result
		d.mem56 = X;
		
		// determine which offset to use from table { 0x18, 0x1A, 0x17, 0x17, 0x17 }
		// T, S, Z                0          0x18
		// CH, J, SH, ZH          1          0x1A
		// P, F*, V, TH, DH       2          0x17
		// /H                     3          0x17
		// /X                     4          0x17

		// get value from the table
		d.mem53 = RenderTabs.tab48426[X];
		d.mem47 = X;      //46016+mem[56]*256
		
		// voiced sample?
		A = d.mem39 & 248;
		if(A == 0) {
			// voiced phoneme: Z*, ZH, V*, DH
			Y = d.mem49;
			A = pitches[d.mem49] >> 4;
			
			// jump to voiced portion
			//goto pos48315;
		}
		
		Y = A ^ 255;
		var skipFlag:Int = 0;
		while(true){
		//pos48274:
			if (skipFlag < 1) {
				log("pos48274");	
				skipFlag = 0;
				// step through the 8 bits in the sample
				d.mem56 = 8;
				
				// get the next sample from the table
				// mem47*256 = offset to start of samples
				A = RenderTabs.sampleTable[d.mem47 * 256 + Y];
			}
		//pos48280:
			if (skipFlag < 2) {
				log("pos48280");
				skipFlag = 0;	
				// left shift to get the high bit
				tempA = A;
				A = A << 1;
				A = A % 256;
				//48281: BCC 48290
				
				// bit not set?
				if ((tempA & 128) == 0) {
					// convert the bit to value from table
					X = d.mem53;
					//mem[54296] = X;
					// output the byte
					Output(1, X);
					// if X != 0, exit loop
					if (X != 0) { 
						//goto pos48296;
						skipFlag = 2;
						continue;
					}
				}
				
				// output a 5 for the on bit
				Output(2, 5);
				

				//48295: NOP
			}
		//pos48296:
			if (skipFlag < 3) {
				log("pos48296");
				skipFlag = 0;	
				X = 0;

				// decrement counter
				d.mem56--;
				if (d.mem56 < 0) {
					d.mem56 += 256;
				}
				
				// if not done, jump to top of loop
				if (d.mem56 != 0) {
					//goto pos48280;
					skipFlag = 1;
					continue;
				}
				
				// increment position
				Y++;
				Y = Y % 256;
				if (Y != 0) {
					//goto pos48274;
					skipFlag = 0;
					continue;
				}
				
				// restore values and return
				d.mem44 = 1;
				Y = d.mem49;
				return mem66;

			}
			var phase1:Int; //unsigned char 
		
		//pos48315:
			if (skipFlag < 4) {
				log("pos48315");	
				// handle voiced samples here

			   // number of samples?
				phase1 = A ^ 255;

				Y = mem66;
				do {
					//pos48321:

					// shift through all 8 bits
					d.mem56 = 8;
					//A = Read(mem47, Y);
					
					// fetch value from table
					A = RenderTabs.sampleTable[d.mem47*256+Y];

					// loop 8 times
					//pos48327:
					do {
						//48327: ASL A
						//48328: BCC 48337
						
						// left shift and check high bit
						tempA = A;
						A = A << 1;
						A = A % 256;
						if ((tempA & 128) != 0) {
							// if bit set, output 26
							X = 26;
							Output(3, X);
						} else {
							//timetable 4
							// bit is not set, output a 6
							X=6;
							Output(4, X);
						}

						d.mem56--;
					} while(d.mem56 != 0);

					// move ahead in the table
					Y++;
					Y = Y % 256;
					
					// continue until counter done
					phase1++;
					phase1 = phase1 % 256;
				} while (phase1 != 0);
			}
			break;
		}
		//	if (phase1 != 0) goto pos48321;
		
		// restore values and return
		A = 1;
		d.mem44 = 1;
		mem66 = Y;
		Y = d.mem49;
		return mem66;
	}

	
	function Render():Void {
		var phase1:Int = 0;  //mem43
		var phase2:Int = 0;
		var phase3:Int = 0;
		var mem66:Int = 0;
		var mem38:Int = 0;
		var mem40:Int = 0;
		var speedcounter:Int = 0; //mem45
		var mem48:Int = 0;
		var i:Int = 0;
		var carry:Bool;
		
		if (d.phonemeIndexOutput[0] == 255) {
			return; //exit if no data
		}

		A = 0;
		X = 0;
		d.mem44 = 0;


	// CREATE FRAMES
	//
	// The length parameter in the list corresponds to the number of frames
	// to expand the phoneme to. Each frame represents 10 milliseconds of time.
	// So a phoneme with a length of 7 = 7 frames = 70 milliseconds duration.
	//
	// The parameters are copied from the phoneme to the frame verbatim.

	// pos47587:
	do {
		// get the index
		Y = d.mem44;
		// get the phoneme at the index
		A = d.phonemeIndexOutput[d.mem44];
		d.mem56 = A;
		
		// if terminal phoneme, exit the loop
		if (A == 255) break;
		
		// period phoneme *.
		if (A == 1) {
			// add rising inflection
			A = 1;
			mem48 = 1;
			//goto pos48376;
			AddInflection(mem48, phase1);
		}
		/*
		if (A == 2) goto pos48372;
		*/
		
		// question mark phoneme?
		if (A == 2) {
			// create falling inflection
			mem48 = 255;
			AddInflection(mem48, phase1);
		}
		//	pos47615:

		// get the stress amount (more stress = higher pitch)
		phase1 = RenderTabs.tab47492[d.stressOutput[Y] + 1];
		
		// get number of frames to write
		phase2 = d.phonemeLengthOutput[Y];
		Y = d.mem56;
		
		// copy from the source to the frames list
		do
		{
			frequency1[X] = RenderTabs.freq1data[Y];     // F1 frequency
			frequency2[X] = RenderTabs.freq2data[Y];     // F2 frequency
			frequency3[X] = RenderTabs.freq3data[Y];     // F3 frequency
			amplitude1[X] = RenderTabs.ampl1data[Y];     // F1 amplitude
			amplitude2[X] = RenderTabs.ampl2data[Y];     // F2 amplitude
			amplitude3[X] = RenderTabs.ampl3data[Y];     // F3 amplitude
			sampledConsonantFlag[X] = RenderTabs.sampledConsonantFlags[Y];        // phoneme data for sampled consonants
			pitches[X] = d.pitch + phase1;      // pitch
			pitches[X] = pitches[X] % 256;
			X++;
			X = X % 256;
			phase2--;
			if (phase2 < 0) {
				phase2 += 256;
			}
		} while(phase2 != 0);
		d.mem44++;
		d.mem44 = d.mem44 % 256;
	} while (d.mem44 != 0);
	
	// -------------------
	//pos47694:

	// CREATE TRANSITIONS
	//
	// Linear transitions are now created to smoothly connect the
	// end of one sustained portion of a phoneme to the following
	// phoneme. 
	//
	// To do this, three tables are used:
	//
	//  Table         Purpose
	//  =========     ==================================================
	//  blendRank     Determines which phoneme's blend values are used.
	//
	//  blendOut      The number of frames at the end of the phoneme that
	//                will be used to transition to the following phoneme.
	//
	//  blendIn       The number of frames of the following phoneme that
	//                will be used to transition into that phoneme.
	//
	// In creating a transition between two phonemes, the phoneme
	// with the HIGHEST rank is used. Phonemes are ranked on how much
	// their identity is based on their transitions. For example, 
	// vowels are and diphthongs are identified by their sustained portion, 
	// rather than the transitions, so they are given low values. In contrast,
	// stop consonants (P, B, T, K) and glides (Y, L) are almost entirely
	// defined by their transitions, and are given high rank values.
	//
	// Here are the rankings used by SAM:
	//
	//     Rank    Type                         Phonemes
	//     2       All vowels                   IY, IH, etc.
	//     5       Diphthong endings            YX, WX, ER
	//     8       Terminal liquid consonants   LX, WX, YX, N, NX
	//     9       Liquid consonants            L, RX, W
	//     10      Glide                        R, OH
	//     11      Glide                        WH
	//     18      Voiceless fricatives         S, SH, F, TH
	//     20      Voiced fricatives            Z, ZH, V, DH
	//     23      Plosives, stop consonants    P, T, K, KX, DX, CH
	//     26      Stop consonants              J, GX, B, D, G
	//     27-29   Stop consonants (internal)   **
	//     30      Unvoiced consonants          /H, /X and Q*
	//     160     Nasal                        M
	//
	// To determine how many frames to use, the two phonemes are 
	// compared using the blendRank[] table. The phoneme with the 
	// higher rank is selected. In case of a tie, a blend of each is used:
	//
	//      if blendRank[phoneme1] ==  blendRank[phomneme2]
	//          // use lengths from each phoneme
	//          outBlendFrames = outBlend[phoneme1]
	//          inBlendFrames = outBlend[phoneme2]
	//      else if blendRank[phoneme1] > blendRank[phoneme2]
	//          // use lengths from first phoneme
	//          outBlendFrames = outBlendLength[phoneme1]
	//          inBlendFrames = inBlendLength[phoneme1]
	//      else
	//          // use lengths from the second phoneme
	//          // note that in and out are SWAPPED!
	//          outBlendFrames = inBlendLength[phoneme2]
	//          inBlendFrames = outBlendLength[phoneme2]
	//
	// Blend lengths can't be less than zero.
	//
	// Transitions are assumed to be symetrical, so if the transition 
	// values for the second phoneme are used, the inBlendLength and 
	// outBlendLength values are SWAPPED.
	//
	// For most of the parameters, SAM interpolates over the range of the last
	// outBlendFrames-1 and the first inBlendFrames.
	//
	// The exception to this is the Pitch[] parameter, which is interpolates the
	// d.pitch from the CENTER of the current phoneme to the CENTER of the next
	// phoneme.
	//
	// Here are two examples. First, For example, consider the word "SUN" (S AH N)
	//
	//    Phoneme   Duration    BlendWeight    OutBlendFrames    InBlendFrames
	//    S         2           18             1                 3
	//    AH        8           2              4                 4
	//    N         7           8              1                 2
	//
	// The formant transitions for the output frames are calculated as follows:
	//
	//     flags ampl1 freq1 ampl2 freq2 ampl3 freq3 d.pitch
	//    ------------------------------------------------
	// S
	//    241     0     6     0    73     0    99    61   Use S (weight 18) for transition instead of AH (weight 2)
	//    241     0     6     0    73     0    99    61   <-- (OutBlendFrames-1) = (1-1) = 0 frames
	// AH
	//      0     2    10     2    66     0    96    59 * <-- InBlendFrames = 3 frames
	//      0     4    14     3    59     0    93    57 *
	//      0     8    18     5    52     0    90    55 *
	//      0    15    22     9    44     1    87    53
	//      0    15    22     9    44     1    87    53   
	//      0    15    22     9    44     1    87    53   Use N (weight 8) for transition instead of AH (weight 2).
	//      0    15    22     9    44     1    87    53   Since N is second phoneme, reverse the IN and OUT values.
	//      0    11    17     8    47     1    98    56 * <-- (InBlendFrames-1) = (2-1) = 1 frames
	// N
	//      0     8    12     6    50     1   109    58 * <-- OutBlendFrames = 1
	//      0     5     6     5    54     0   121    61
	//      0     5     6     5    54     0   121    61
	//      0     5     6     5    54     0   121    61
	//      0     5     6     5    54     0   121    61
	//      0     5     6     5    54     0   121    61
	//      0     5     6     5    54     0   121    61
	//
	// Now, consider the reverse "NUS" (N AH S):
	//
	//     flags ampl1 freq1 ampl2 freq2 ampl3 freq3 d.pitch
	//    ------------------------------------------------
	// N
	//     0     5     6     5    54     0   121    61
	//     0     5     6     5    54     0   121    61
	//     0     5     6     5    54     0   121    61
	//     0     5     6     5    54     0   121    61
	//     0     5     6     5    54     0   121    61   
	//     0     5     6     5    54     0   121    61   Use N (weight 8) for transition instead of AH (weight 2)
	//     0     5     6     5    54     0   121    61   <-- (OutBlendFrames-1) = (1-1) = 0 frames
	// AH
	//     0     8    11     6    51     0   110    59 * <-- InBlendFrames = 2
	//     0    11    16     8    48     0    99    56 *
	//     0    15    22     9    44     1    87    53   Use S (weight 18) for transition instead of AH (weight 2)
	//     0    15    22     9    44     1    87    53   Since S is second phoneme, reverse the IN and OUT values.
	//     0     9    18     5    51     1    90    55 * <-- (InBlendFrames-1) = (3-1) = 2
	//     0     4    14     3    58     1    93    57 *
	// S
	//   241     2    10     2    65     1    96    59 * <-- OutBlendFrames = 1
	//   241     0     6     0    73     0    99    61

		A = 0;
		d.mem44 = 0;
		d.mem49 = 0; // d.mem49 starts at as 0
		X = 0;
		while(true) //while No. 1
		{
	 
			// get the current and following phoneme
			Y = d.phonemeIndexOutput[X];
			A = d.phonemeIndexOutput[X+1];
			X++;
			X = X % 256;

			// exit loop at end token
			if (A == 255) {
				break;//goto pos47970;
			}


			// get the ranking of each phoneme
			X = A;
			d.mem56 = RenderTabs.blendRank[A];
			A = RenderTabs.blendRank[Y];
			
			// compare the rank - lower rank value is stronger
			if (A == d.mem56) {
				// same rank, so use out blend lengths from each phoneme
				phase1 = RenderTabs.outBlendLength[Y];
				phase2 = RenderTabs.outBlendLength[X];
			} else if (A < d.mem56) {
				// first phoneme is stronger, so us it's blend lengths
				phase1 = RenderTabs.inBlendLength[X];
				phase2 = RenderTabs.outBlendLength[X];
			} else {
				// second phoneme is stronger, so use it's blend lengths
				// note the out/in are swapped
				phase1 = RenderTabs.outBlendLength[Y];
				phase2 = RenderTabs.inBlendLength[Y];
			}

			Y = d.mem44;
			A = d.mem49 + d.phonemeLengthOutput[d.mem44]; // A is d.mem49 + length
			d.mem49 = A; // d.mem49 now holds length + position
			A = A + phase2; //Maybe Problem because of carry flag
			A = A % 256;

			//47776: ADC 42
			speedcounter = A;
			d.mem47 = 168;
			phase3 = d.mem49 - phase1; // what is d.mem49
			A = phase1 + phase2; // total transition?
			A = A % 256;
			mem38 = A;
			
			X = A;
			X -= 2;
			if (X < 0) {
				X += 256;
			}
			
			if ((X & 128) == 0) {
				do   //while No. 2
				{
					//pos47810:

				  // d.mem47 is used to index the tables:
				  // 168  pitches[]
				  // 169  frequency1
				  // 170  frequency2
				  // 171  frequency3
				  // 172  amplitude1
				  // 173  amplitude2
				  // 174  amplitude3

					mem40 = mem38;

					if (d.mem47 == 168)     // d.pitch
					{
							  
					   // unlike the other values, the pitches[] interpolates from 
					   // the middle of the current phoneme to the middle of the 
					   // next phoneme
							  
						var mem36:Int;
						var mem37:Int;
						// half the width of the current phoneme
						mem36 = d.phonemeLengthOutput[d.mem44] >> 1;
						// half the width of the next phoneme
						mem37 = d.phonemeLengthOutput[d.mem44+1] >> 1;
						// sum the values
						mem40 = mem36 + mem37; // length of both halves
						mem37 += d.mem49; // center of next phoneme
						mem36 = d.mem49 - mem36; // center index of current phoneme
						A = read(d.mem47, mem37); // value at center of next phoneme - end interpolation value
						//A = mem[address];
						
						Y = mem36; // start index of interpolation
						d.mem53 = A - read(d.mem47, mem36); // value to center of current phoneme
						if (d.mem53 < 0) {
							d.mem53 += 256;
						}
					} else {
						// value to interpolate to
						A = read(d.mem47, speedcounter);
						// position to start interpolation from
						Y = phase3;
						// value to interpolate from
						d.mem53 = A - read(d.mem47, phase3);
						if (d.mem53 < 0) {
							d.mem53 += 256;
						}
					}
					
					//Code47503(mem40);
					// ML : Code47503 is division with remainder, and d.mem50 gets the sign
					
					// calculate change per frame
					var foff = d.mem53;
					if (foff > 127) foff -= 255;
					
					d.mem50 = (((d.mem53) < 0) ? 128 : 0);
					
					d.mem51 = Std.int(Math.abs(foff)) % mem40;
					foff = Std.int(foff / mem40);
					
					d.mem53 = foff % 256;

					// interpolation range
					X = mem40; // number of frames to interpolate over
					Y = phase3; // starting frame


					// linearly interpolate values

					d.mem56 = 0;
					//47907: CLC
					//pos47908:
					while(true)     //while No. 3
					{
						A = read(d.mem47, Y) + d.mem53; //carry alway cleared

						mem48 = A;
						Y++;
						Y = Y % 256;
						X--;
						if ( X < 0) {
							X += 256;
						}
						if (X == 0) {
							break;
						}

						d.mem56 += d.mem51;
						d.mem56 = d.mem56 % 256;
						
						if (d.mem56 >= mem40)  //???
						{
							d.mem56 -= mem40; //carry? is set
							if (d.mem56 < 0) {
								d.mem56 += 256;
							}
							//if ((d.mem56 & 128)==0)
							if ((d.mem50 & 128)==0)
							{
								//47935: BIT 50
								//47937: BMI 47943
								if (mem48 != 0) {
									mem48++;
									mem48 = mem48 % 256;
								}
							} else {
								mem48--;
								if (mem48 < 0) {
									mem48 += 256;
								}
							}
						}
						//pos47945:
						write(d.mem47, Y, mem48);
					} //while No. 3

					//pos47952:
					d.mem47++;
					d.mem47 = d.mem47 % 256;
					//if (d.mem47 != 175) goto pos47810;
				} while (d.mem47 != 175);     //while No. 2
			}
			//pos47963:
			d.mem44++;
			d.mem44 = d.mem44 % 256;
			X = d.mem44;
		}  //while No. 1

		//goto pos47701;
		//pos47970:

		// add the length of this phoneme
		mem48 = d.mem49 + d.phonemeLengthOutput[d.mem44];
		mem48 = mem48 % 256;
		

	// ASSIGN PITCH CONTOUR
	//
	// This subtracts the F1 frequency from the d.pitch to create a
	// d.pitch contour. Without this, the output would be at a single
	// d.pitch level (monotone).

		
		// don't adjust d.pitch if in sing mode
		if (!d.singMode) {
			// iterate through the buffer

			for(i in 0...256) {
				// subtract half the frequency of the formant 1.
				// this adds variety to the voice
				pitches[i] -= (frequency1[i] >> 1);
				if (pitches[i] < 0) {
					pitches[i] = pitches[i] + 256;
				}
			}
		}

		phase1 = 0;
		phase2 = 0;
		phase3 = 0;
		d.mem49 = 0;
		speedcounter = 72; //sam standard d.speed

	// RESCALE AMPLITUDE
	//
	// Rescale volume from a linear scale to decibels.
	//

		//amplitude rescaling
		i = 256;
		while(i-- >= 0) {
			amplitude1[i] = RenderTabs.amplitudeRescale[amplitude1[i]];
			amplitude2[i] = RenderTabs.amplitudeRescale[amplitude2[i]];
			amplitude3[i] = RenderTabs.amplitudeRescale[amplitude3[i]];
		}

		Y = 0;
		A = pitches[0];
		
		d.mem44 = A;
		X = A;
		mem38 = A - (A >> 2);     // 3/4*A ???
		if (mem38 < 0) {
			mem38 += 256;
		}

		/*
		if (debug)
		{
			PrintOutput(sampledConsonantFlag, frequency1, frequency2, frequency3, amplitude1, amplitude2, amplitude3, pitches);
		}
		*/

		// PROCESS THE FRAMES
		//
		// In traditional vocal synthesis, the glottal pulse drives filters, which
		// are attenuated to the frequencies of the formants.
		//
		// SAM generates these formants directly with sin and rectangular waves.
		// To simulate them being driven by the glottal pulse, the waveforms are
		// reset at the beginning of each glottal pulse.
		
		//finally the loop for sound output
		//pos48078:
		while(true) {
			// get the sampled information on the phoneme
			A = sampledConsonantFlag[Y];
			d.mem39 = A;
			
			// unvoiced sampled phoneme?
			A = A & 248;
			if(A != 0) {
				// render the sample for the phoneme
				RenderSample(mem66);
				
				// skip ahead two in the phoneme buffer
				Y += 2;
				Y = Y % 256;
				mem48 -= 2;
				if (mem48 < 0) {
					mem48 += 256;
				}
			} else {
				// simulate the glottal pulse and formants
				d.mem56 = RenderTabs.multtable[RenderTabs.sinus[phase1] | amplitude1[Y]];

				carry = false;
				if ((d.mem56 + RenderTabs.multtable[RenderTabs.sinus[phase2] | amplitude2[Y]] ) > 255) {
					carry = true;
				}
				
				d.mem56 += RenderTabs.multtable[RenderTabs.sinus[phase2] | amplitude2[Y]];
				d.mem56 = d.mem56 % 256;
				
				A = d.mem56 + RenderTabs.multtable[RenderTabs.rectangle[phase3] | amplitude3[Y]] + (carry?1:0);
				A = A % 256;
				
				A = ((A + 136) & 255) >> 4; //there must be also a carry
				A = A % 256;
				//mem[54296] = A;
				
				// output the accumulated value
				Output(0, A);
				speedcounter--;
				if (speedcounter < 0) {
					speedcounter += 256;
				}
				
				if (speedcounter == 0) {
					Y++; //go to next amplitude
					Y = Y % 256;
					
					
					// decrement the frame count
					mem48--;
					if (mem48 < 0) {
						mem48 += 256;
					}
				}
			}
			
			if(speedcounter == 0){
				// if the frame count is zero, exit the loop
				if (mem48 == 0) 	{
					return;
				}
				
				speedcounter = d.speed;
			}
			
			var skipSteps = 0;
			var continueLoop = true;
			while (continueLoop) {
			//pos48155:
				if (skipSteps < 1) {
					log("pos48155");
					skipSteps = 0;
					// decrement the remaining length of the glottal pulse
					d.mem44--;
					if (d.mem44 < 0) {
						d.mem44 += 256;
					}
				}
				
				// finished with a glottal pulse?
			//pos48159:
				if (d.mem44 == 0 || skipSteps == 1) {
					log("pos48195");
					skipSteps = 0;
	
					// fetch the next glottal pulse length
					A = pitches[Y];
					d.mem44 = A;
					A = A - (A>>2);
					mem38 = A;
					
					// reset the formant wave generators to keep them in 
					// sync with the glottal pulse
					phase1 = 0;
					phase2 = 0;
					phase3 = 0;
					continueLoop = false;
					continue;
				}
				
				// decrement the count
				mem38--;
				if (mem38 < 0) {
					mem38 += 256;
				}
				
				// is the count non-zero and the sampled flag is zero?
				if((mem38 != 0) || (d.mem39 == 0)) {
					// reset the phase of the formants to match the pulse
					phase1 += frequency1[Y];
					phase1 = phase1 % 256;
					phase2 += frequency2[Y];
					phase2 = phase2 % 256;
					phase3 += frequency3[Y];
					phase3 = phase3 % 256;
					
					continueLoop = false;
					continue;
				}
				
				// voiced sampled phonemes interleave the sample with the
				// glottal pulse. The sample flag is non-zero, so render
				// the sample for the phoneme.
				mem66 = RenderSample(mem66);
				//goto pos48159;
				skipSteps = 1;
			}
		} //while


		// The following code is never reached. It's left over from when
		// the voiced sample code was part of this loop, instead of part
		// of RenderSample();
/*
		//pos48315:
		int tempA;
		phase1 = A ^ 255;
		Y = mem66;
		do {
			//pos48321:

			d.mem56 = 8;
			A = Read(d.mem47, Y);

			//pos48327:
			do
			{
				//48327: ASL A
				//48328: BCC 48337
				tempA = A;
				A = A << 1;
				if ((tempA & 128) != 0)
				{
					X = 26;
					// mem[54296] = X;
					bufferpos += 150;
					buffer[bufferpos/50] = (X & 15)*16;
				} else
				{
					//mem[54296] = 6;
					X=6; 
					bufferpos += 150;
					buffer[bufferpos/50] = (X & 15)*16;
				}

				for(X = wait2; X>0; X--); //wait
				d.mem56--;
			} while(d.mem56 != 0);

			Y++;
			phase1++;

		} while (phase1 != 0);
		//	if (phase1 != 0) goto pos48321;	
		*/
		A = 1;
		d.mem44 = 1;
		mem66 = Y;
		Y = d.mem49;
		return;
	}

	function AddInflection(mem48:Int, phase1:Int)
	{
		//pos48372:
		//	mem48 = 255;
		//pos48376:
			   
		// store the location of the punctuation
		d.mem49 = X;
		A = X;
		var Atemp = A;
		
		// backup 30 frames
		A = A - 30;
		if (A < 0) {
			A += 256;
		}
		// if index is before buffer, point to start of buffer
		if (Atemp <= 30) {
			A = 0;
		}
		X = A;

		// FIXME: Explain this fix better, it's not obvious
		// ML : A =, fixes a problem with invalid d.pitch with '.'
		while ( (A = pitches[X]) == 127) {
			X++;
			X = X % 256;
		}
		
		var first = true;
		
		while(true){
			if (first || pitches[X] == 255) 
			{
				//48398: CLC
				//48399: ADC 48
				
				// add the inflection direction
				A += mem48;
				A = A % 256;
				phase1 = A;
				
				// set the inflection
				pitches[X] = A;
			}
			
			first = false;
				
			// increment the position
			X++;
			X = X % 256;
			
			// exit if the punctuation has been reached
			if (X == d.mem49) {
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
				A = A % 256;
				
				if (temp > 255) {
					carry = 1;
				}
				
				mem39215 = A;
			}
			temp = mem39215 & 1;
			mem39215 = (mem39215 >> 1) | ((carry != 0)?128:0);
			carry = temp;
			carry = carry % 256;
			X--;
		} while (X != 0);
		
		temp = mem39214 & 128;
		mem39214 = (mem39214 << 1) | ((carry != 0)?1:0);
		mem39214 = mem39214 % 256;
		
		carry = temp;
		carry = carry % 256;
		
		temp = mem39215 & 128;
		mem39215 = (mem39215 << 1) | ((carry != 0)?1:0);
		mem39215 = mem39215 % 256;
		
		carry = temp;
		carry = carry % 256;

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
			if (initialFrequency != 0) {
				newFrequency = trans(mouth, initialFrequency);
			}
			
			RenderTabs.freq1data[pos] = newFrequency;
				   
			// recalculate throat frequency
			initialFrequency = throatFormants5_29[pos];
			if (initialFrequency != 0) {
				newFrequency = trans(throat, initialFrequency);
			}
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
}