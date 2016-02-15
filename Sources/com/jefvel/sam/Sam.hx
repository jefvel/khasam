package com.jefvel.sam;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Int32Array;
import haxe.Timer;
import kha.audio1.Audio;

/**
 * ...
 * @author jefvel
 */
class Sam {

	var input:Vector<Int>;
	var speed:Int = 72;
	var pitch:Int = 64;
	var mouth:Int = 128;
	var throat:Int = 128;
	var singMode:Bool = true;
	
	var mem39:Int;
	var mem44:Int;
	var mem47:Int;
	var mem49:Int;
	var mem50:Int;
	var mem51:Int;
	var mem56:Int;
	
	var mem59:Int = 0;
	
	var o:SamTabs;
	var p:ReciterTabs;
	var i:RenderTabs;
	
	var render:SamRender;
	var reciter:SamReciter;
	
	var d:SamData;
	
	public static var bufferPos = 0;
	public static var buffer:Vector<Int> = new Vector<Int>(22050 * 10);
	
	public function new(samInput:String = "lol") {
		d = new SamData();

		trace("Sam input: " + samInput);
		
		render = new SamRender();
		var s1 = Timer.stamp();
		var o = SamReciter.textToPhonemes(samInput);
		input = SamReciter.result;
		
		var s2 = Timer.stamp() - s1;
		trace("Reciter took " + s2 + " seconds." );
		
		var res = "";
		for (i in input) {
			res += String.fromCharCode(i);
		}
		
		trace("Reciter result: " + res);
		
		SamInit();
	}
	
	function init() {
		render.setMouthThroat(mouth, throat);
		bufferPos = 0;
		
		for (i in 0...256) {
			d.stress[i] = 0;
			d.phonemeLength[i] = 0;
			
		}
		for (i in 0...60) {
			d.phonemeIndexOutput[i] = 0;
			d.stressOutput[i] = 0;
			d.phonemeLengthOutput[i] = 0;
		}
		
		d.phonemeIndex[255] = 255;
	}
	
	public function SamInit() {
		init();
		d.phonemeIndex[255] = 32;
		
		if (parser1() == 0) {
			trace("parser 1 error. aborting Sam. He died, you monster.");
			return;
		}
		
		Parser2();
		PrintPhonemes(d.phonemeIndex, d.phonemeLength, d.stress);
		
		CopyStress();
		SetPhonemeLength();
		AdjustLengths();
		Code41240();
		
		do {
			d.A = d.phonemeIndex[d.X];
			if (d.A > 80) {
				d.phonemeIndex[d.X] = 255;
				break; // error: delete all behind it
			}
			d.X++;
			d.X = d.X % 256;
		} while (d.X != 0);
		
		InsertBreath();
		
		PrintPhonemes(d.phonemeIndex, d.phonemeLength, d.stress);
	
		//trace(d);
		render.PrepareOutput(d);
		trace("Buf len:" + Sam.bufferPos);
	}
	
	
	
	function PrintPhonemes(phonemeindex:Vector<Int>, phonemeLength:Vector<Int>, stress:Vector<Int>) {
		var i = 0;
		trace("===========================================\n");

		trace("Internal Phoneme presentation:\n\n");
		trace(" idx    phoneme  length  stress\n");
		trace("------------------------------\n");
		while((phonemeindex[i] != 255) && (i < 255))
		{
			if (phonemeindex[i] < 81) {
				trace(" "+ 
				phonemeindex[i] + ", "+ 
				SamTabs.signInputTable1[phonemeindex[i]]+ ", "+ 
				SamTabs.signInputTable2[phonemeindex[i]]+ ", "+
				phonemeLength[i]+ ", "+
				stress[i]
				);
			} else {
				trace(" "+ phonemeindex[i]+ ", "+ phonemeLength[i] + ", "+ stress[i]);
			}
			i++;
		}
		trace("===========================================\n");
		//trace("\n");
	}
	
	
	function parser1():Int {
		var i:Int;//Int
		var sign1:Int;//Char
		var sign2:Int;//Char
		var position:Int = 0;//Char
		d.X = 0;
		d.A = 0;
		d.Y = 0;
		
		// CLEAR THE STRESS TABLE
		for(i in 0...256) {
			d.stress[i] = 0;
		}
		
		// THIS CODE MATCHES THE PHONEME LETTERS TO THE TABLE
		// pos41078:
		while(true) {
			// GET THE FIRST CHARACTER FROM THE PHONEME BUFFER
			sign1 = input[d.X];
			// TEST FOR 155 () END OF LINE MARKER
			if (sign1 == 155) {
			   // MARK ENDPOINT AND RETURN
				d.phonemeIndex[position] = 255;      //mark endpoint
				// REACHED END OF PHONEMES, SO EXIT
				return 1;       //all ok
			}
			
			// GET THE NEXT CHARACTER FROM THE BUFFER
			d.X++;
			d.X = d.X % 256;
			sign2 = input[d.X];
			
			// NOW sign1 = FIRST CHARACTER OF PHONEME, AND sign2 = SECOND CHARACTER OF PHONEME

		   // TRY TO MATCH PHONEMES ON TWO TWO-CHARACTER NAME
		   // IGNORE PHONEMES IN TABLE ENDING WITH WILDCARDS

			// SET INDEX TO 0
			d.Y = 0;
			//pos41095:
			
			var megaBreak = false;
			while (true) { 
				//trace("pos41095");
				// GET FIRST CHARACTER AT POSITION Y IN signInputTable
				// --> should change name to PhonemeNameTable1
				d.A = SamTabs.signInputTable1[d.Y].charCodeAt(0);
				
				// FIRST CHARACTER MATCHES?
				if (d.A == sign1) {
				   // GET THE CHARACTER FROM THE PhonemeSecondLetterTable
					d.A = SamTabs.signInputTable2[d.Y].charCodeAt(0);
					// NOT A SPECIAL AND MATCHES SECOND CHARACTER?
					if ((d.A != '*'.charCodeAt(0)) && (d.A == sign2)) {
					   // STORE THE INDEX OF THE PHONEME INTO THE phomeneIndexTable
						d.phonemeIndex[position] = d.Y;
						
						// ADVANCE THE POINTER TO THE phonemeIndexTable
						position++;
						position = position % 256;
						// ADVANCE THE POINTER TO THE phonemeInputBuffer
						d.X++;
						d.X = d.X % 256;

						// CONTINUE PARSING
						megaBreak = true;
						break;
					}
				}
				
				// NO MATCH, TRY TO MATCH ON FIRST CHARACTER TO WILDCARD NAMES (ENDING WITH '*')
				
				// ADVANCE TO THE NEXT POSITION
				d.Y++;
				d.Y = d.Y % 256;
				// IF NOT END OF TABLE, CONTINUE
				if (d.Y != 81) {
					//goto pos41095;
					continue;
				}
				
				break;
			}
			
			if (megaBreak) {
				continue;
			}

			// REACHED END OF TABLE WITHOUT AN EXACT (2 CHARACTER) MATCH.
			// THIS TIME, SEARCH FOR A 1 CHARACTER MATCH AGAINST THE WILDCARDS

			// RESET THE INDEX TO POINT TO THE START OF THE PHONEME NAME TABLE
			d.Y = 0;
			//pos41134:
			megaBreak = false;
			while (true) {
				//trace("pos41134");
				// DOES THE PHONEME IN THE TABLE END WITH '*'?
				if (SamTabs.signInputTable2[d.Y] == '*') {
				// DOES THE FIRST CHARACTER MATCH THE FIRST LETTER OF THE PHONEME
					if (SamTabs.signInputTable1[d.Y].charCodeAt(0) == sign1) {
						// SAVE THE POSITION AND MOVE AHEAD
						d.phonemeIndex[position] = d.Y;
						
						// ADVANCE THE POINTER
						position++;
						position = position % 256;
						
						// CONTINUE THROUGH THE LOOP
						megaBreak = true;
						break;
					}
				}
				
				d.Y++;
				d.Y = d.Y % 256;
				if (d.Y != 81) {
					//	goto pos41134; //81 is size of PHONEME NAME table
					continue;
				}
				break;
			}
			
			if (megaBreak) {
				continue;
			}

			// FAILED TO MATCH WITH A WILDCARD. ASSUME THIS IS A STRESS
			// CHARACTER. SEARCH THROUGH THE STRESS TABLE

			// SET INDEX TO POSITION 8 (END OF STRESS TABLE)
			d.Y = 8;
			
			// WALK BACK THROUGH TABLE LOOKING FOR A MATCH
			while( (sign1 != SamTabs.stressInputTable[d.Y].charCodeAt(0)) && (d.Y>0)) {
				// DECREMENT INDEX
				d.Y--;
				if (d.Y < 0) {
					d.Y += 256;
				}
			}

			// REACHED THE END OF THE SEARCH WITHOUT BREAKING OUT OF LOOP?
			if (d.Y == 0) {
				//mem[39444] = d.X;
				//41181: JSR 42043 //Error
				// FAILED TO MATCH ANYTHING, RETURN 0 ON FAILURE
				return 0;
			}
			// SET THE STRESS FOR THE PRIOR PHONEME
			d.stress[position-1] = d.Y;
		} //while
	}
	
	function Parser2():Void {
		//if (debug) printf("Parser2\n");
		var pos:Int = 0;//Char //mem66;
		var mem58:Int = 0;//Char

		var skipSteps = 0;
	  // Loop through phonemes
		while (true) {
			skipSteps = 0;
	// SET X TO THE CURRENT POSITION
			d.X = pos;
	// GET THE PHONEME AT THE CURRENT POSITION
			d.A = d.phonemeIndex[pos];

	// DEBUG: Print phoneme and index
			//if (debug && d.A != 255) printf("%d: %c%c\n", d.X, signInputTable1[d.A], signInputTable2[d.A]);

	// Is phoneme pause?
			if (d.A == 0) {
	// Move ahead to the 
				pos++;
				pos = pos % 256;
				continue;
			}
			
	// If end of phonemes flag reached, exit routine
			if (d.A == 255) {
				return;
			}
			
	// Copy the current phoneme index to Y
			d.Y = d.A;

	// RULE: 
	//       <DIPHTONG ENDING WITH WX> -> <DIPHTONG ENDING WITH WX> WX
	//       <DIPHTONG NOT ENDING WITH WX> -> <DIPHTONG NOT ENDING WITH WX> YX
	// Example: OIL, COW


	// Check for DIPHTONG
			if ((SamTabs.flags[d.A] & 16) == 0) {
				//goto pos41457;
			}else{

		// Not a diphthong. Get the stress
				mem58 = d.stress[pos];
				
		// End in IY sound?
				d.A = SamTabs.flags[d.Y] & 32;
				
		// If ends with IY, use YX, else use WX
				if (d.A == 0) d.A = 20; else d.A = 21;    // 'WX' = 20 'YX' = 21
				//pos41443:
		// Insert at WX or YX following, copying the stress

				//if (debug) if (d.A==20) printf("RULE: insert WX following diphtong NOT ending in IY sound\n");
				//if (debug) if (d.A==21) printf("RULE: insert YX following diphtong ending in IY sound\n");
				Insert(pos+1, d.A, mem59, mem58);
				d.X = pos;
		// Jump to ???
				//goto pos41749;
				skipSteps = 6;
			}
			
			//Begin skipstepping
			//YEE
			var breakOut = false;
			while (!breakOut) {
			//pos41457:
				if (skipSteps < 1) {
					skipSteps = 0;
					 
			// RULE:
			//       UL -> AX L
			// Example: MEDDLE
				   
			// Get phoneme
					d.A = d.phonemeIndex[d.X];
			// Skip this rule if phoneme is not UL
					if (d.A != 78) {
						//goto pos41487;  // 'UL'
						skipSteps = 2;
						continue;
					}
					d.A = 24;         // 'L'                 //change 'UL' to 'AX L'
					
					//if (debug) printf("RULE: UL -> AX L\n");
				}

			//pos41466:
				if (skipSteps < 2) {
					skipSteps = 0;
		// Get current phoneme stress
					mem58 = d.stress[d.X];
					
			// Change UL to AX
					d.phonemeIndex[d.X] = 13;  // 'AX'
			// Perform insert. Note code below may jump up here with different values
					Insert(d.X+1, d.A, mem59, mem58);
					pos++;
			// Move to next phoneme
					break;
				}
			//pos41487:
				if (skipSteps < 3) {
					skipSteps = 0;
					 
					// RULE:
					//       UM -> AX M
					// Example: ASTRONOMY
							 
					// Skip rule if phoneme != UM
					if (d.A != 79) {
						//goto pos41495;   // 'UM'
					}else{
						// Jump up to branch - replaces current phoneme with AX and continues
						d.A = 27; // 'M'  //change 'UM' to  'AX M'
						//if (debug) printf("RULE: UM -> AX M\n");
						//goto pos41466;
						skipSteps = 1;
						continue;
					}
				}
			//pos41495:
				if (skipSteps < 4) {
					skipSteps = 0;

			// RULE:
			//       UN -> AX N
			// Example: FUNCTION

					 
			// Skip rule if phoneme != UN
					if (d.A != 80) {
						//goto pos41503; // 'UN'
					}else{
						// Jump up to branch - replaces current phoneme with AX and continues
						d.A = 28;         // 'N' //change UN to 'AX N'
						//if (debug) printf("RULE: UN -> AX N\n");
						//goto pos41466;
						skipSteps = 1;
						continue;
					}
				}
			//pos41503:
				if (skipSteps < 5) {
					skipSteps = 0;
					 
			// RULE:
			//       <STRESSED VOWEL> <SILENCE> <STRESSED VOWEL> -> <STRESSED VOWEL> <SILENCE> Q <VOWEL>
			// EXAMPLE: AWAY EIGHT
					 
					d.Y = d.A;
			// VOWEL set?
					d.A = SamTabs.flags[d.A] & 128;

			// Skip if not a vowel
					if (d.A != 0) {
			// Get the stress
						d.A = d.stress[d.X];

			// If stressed...
						if (d.A != 0) {
			// Get the following phoneme
							d.X++;
							d.X = d.X % 256;
							d.A = d.phonemeIndex[d.X];
			// If following phoneme is a pause

							if (d.A == 0) {
			// Get the phoneme following pause
								d.X++;
								d.X = d.X % 256;
								d.Y = d.phonemeIndex[d.X];

			// Check for end of buffer flag
								if (d.Y == 255) //buffer overflow
			// ??? Not sure about these flags
									d.A = 65&128;
								else
			// And VOWEL flag to current phoneme's flags
									d.A = SamTabs.flags[d.Y] & 128;

			// If following phonemes is not a pause
								if (d.A != 0) {
			// If the following phoneme is not stressed
									d.A = d.stress[d.X];
									if (d.A != 0) {
			// Insert a glottal stop and move forward
										//if (debug) printf("RULE: Insert glottal stop between two stressed vowels with space between them\n");
										// 31 = 'Q'
										Insert(d.X, 31, mem59, 0);
										pos++;
										break;
									}
								}
							}
						}
					}


			// RULES FOR PHONEMES BEFORE R
			//        T R -> CH R
			// Example: TRACK


			// Get current position and phoneme
					d.X = pos;
					d.A = d.phonemeIndex[pos];
					if (d.A != 23) {
						//goto pos41611;     // 'R'
						skipSteps = 5;
						continue;
					}
					
			// Look at prior phoneme
					d.X--;
					if (d.X < 0) {
						d.X += 256;
					}
					d.A = d.phonemeIndex[pos-1];
					//pos41567:
					if (d.A == 69)                    // 'T'
					{
			// Change T to CH
						//if (debug) printf("RULE: T R -> CH R\n");
						d.phonemeIndex[pos-1] = 42;
						//goto pos41779;
						skipSteps = 7;
						continue;
					}


			// RULES FOR PHONEMES BEFORE R
			//        D R -> J R
			// Example: DRY

			// Prior phonemes D?
					if (d.A == 57)                    // 'D'
					{
			// Change D to J
						d.phonemeIndex[pos-1] = 44;
						//if (debug) printf("RULE: D R -> J R\n");
						//goto pos41788;
						skipSteps = 8;
						continue;
					}

			// RULES FOR PHONEMES BEFORE R
			//        <VOWEL> R -> <VOWEL> RX
			// Example: ART


			// If vowel flag is set change R to RX
					d.A = SamTabs.flags[d.A] & 128;
					//if (debug) printf("RULE: R -> RX\n");
					if (d.A != 0) {
						d.phonemeIndex[pos] = 18;  // 'RX'
					}
					
			// continue to next phoneme
					pos++;
					break;
				}
			//pos41611:
				if (skipSteps < 6) {
					skipSteps = 0;

			// RULE:
			//       <VOWEL> L -> <VOWEL> LX
			// Example: ALL

			// Is phoneme L?
					if (d.A == 24)    // 'L'
					{
			// If prior phoneme does not have VOWEL flag set, move to next phoneme
						if ((SamTabs.flags[d.phonemeIndex[pos-1]] & 128) == 0) {pos++; break;}
			// Prior phoneme has VOWEL flag set, so change L to LX and move to next phoneme
						//if (debug) printf("RULE: <VOWEL> L -> <VOWEL> LX\n");
						d.phonemeIndex[d.X] = 19;     // 'LX'
						pos++;
						break;
					}
					
			// RULE:
			//       G S -> G Z
			//
			// Can't get to fire -
			//       1. The G -> GX rule intervenes
			//       2. Reciter already replaces GS -> GZ

			// Is current phoneme S?
					if (d.A == 32)    // 'S'
					{
			// If prior phoneme is not G, move to next phoneme
						if (d.phonemeIndex[pos - 1] != 60) {
							pos++; 
							break;
						}
			// Replace S with Z and move on
						//if (debug) printf("RULE: G S -> G Z\n");
						d.phonemeIndex[pos] = 38;    // 'Z'
						pos++;
						break;
					}

			// RULE:
			//             K <VOWEL OR DIPHTONG NOT ENDING WITH IY> -> KX <VOWEL OR DIPHTONG NOT ENDING WITH IY>
			// Example: COW

			// Is current phoneme K?
					if (d.A == 72)    // 'K'
					{
			// Get next phoneme
						d.Y = d.phonemeIndex[pos+1];
			// If at end, replace current phoneme with KX
						if (d.Y == 255) d.phonemeIndex[pos] = 75; // ML : prevents an index out of bounds problem		
						else
						{
			// VOWELS AND DIPHTONGS ENDING WITH IY SOUND flag set?
							d.A = SamTabs.flags[d.Y] & 32;
							//if (debug) if (d.A==0) printf("RULE: K <VOWEL OR DIPHTONG NOT ENDING WITH IY> -> KX <VOWEL OR DIPHTONG NOT ENDING WITH IY>\n");
			// Replace with KX
							if (d.A == 0) d.phonemeIndex[pos] = 75;  // 'KX'
						}
					}
					else

			// RULE:
			//             G <VOWEL OR DIPHTONG NOT ENDING WITH IY> -> GX <VOWEL OR DIPHTONG NOT ENDING WITH IY>
			// Example: GO


			// Is character a G?
					if (d.A == 60)   // 'G'
					{
			// Get the following character
						var index:Int = d.phonemeIndex[pos+1];// char
						
			// At end of buffer?
						if (index == 255) //prevent buffer overflow
						{
							pos++; 
							index = index % 256;
							break;
						}
						else
			// If diphtong ending with YX, move continue processing next phoneme
						if ((SamTabs.flags[index] & 32) != 0) {
							pos++;
							break;
						}
			// replace G with GX and continue processing next phoneme
						//if (debug) printf("RULE: G <VOWEL OR DIPHTONG NOT ENDING WITH IY> -> GX <VOWEL OR DIPHTONG NOT ENDING WITH IY>\n");
						d.phonemeIndex[pos] = 63; // 'GX'
						pos++;
						break;
					}
					
			// RULE:
			//      S P -> S B
			//      S T -> S D
			//      S K -> S G
			//      S KX -> S GX
			// Examples: SPY, STY, SKY, SCOWL
					
					d.Y = d.phonemeIndex[pos];
					//pos41719:
					// Replace with softer version?
					d.A = SamTabs.flags[d.Y] & 1;
					if (d.A == 0) {
						//goto pos41749;
						skipSteps = 6;
						continue;
					}
					d.A = d.phonemeIndex[pos-1];
					if (d.A != 32)    // 'S'
					{
						d.A = d.Y;
						//goto pos41812;
						skipSteps = 9;
						continue;
					}
					// Replace with softer version
					//if (debug) printf("RULE: S* %c%c -> S* %c%c\n", signInputTable1[Y], signInputTable2[Y],signInputTable1[Y-12], signInputTable2[Y-12]);
					d.phonemeIndex[pos] = d.Y-12;
					pos++;
					break;
				}
				
			//pos41749:
				if (skipSteps < 7) {
					skipSteps = 0;
							 
					// RULE:
					//      <ALVEOLAR> UW -> <ALVEOLAR> UX
					//
					// Example: NEW, DEW, SUE, ZOO, THOO, TOO

					//       UW -> UX

					d.A = d.phonemeIndex[d.X];
					if (d.A == 53)    // 'UW'
					{
						// ALVEOLAR flag set?
						d.Y = d.phonemeIndex[d.X-1];
						d.A = SamTabs.flags2[d.Y] & 4;
						// If not set, continue processing next phoneme
						if (d.A == 0) {
							pos++; 
							break;
						}
						
						//if (debug) printf("RULE: <ALVEOLAR> UW -> <ALVEOLAR> UX\n");
						
						d.phonemeIndex[d.X] = 16;
						pos++;
						break;
					}
				}
				
			//pos41779:
				if (skipSteps < 8) {
					skipSteps = 0;

			// RULE:
			//       CH -> CH CH' (CH requires two phonemes to represent it)
			// Example: CHEW

					if (d.A == 42)    // 'CH'
					{
						//        pos41783:
						//if (debug) printf("CH -> CH CH+1\n");
						Insert(d.X+1, d.A+1, mem59, d.stress[d.X]);
						pos++;
						break;
					}
				}
				
			//pos41788:
				if (skipSteps < 9) {
					skipSteps = 0;
					 
			// RULE:
			//       J -> J J' (J requires two phonemes to represent it)
			// Example: JAY
					 

					if (d.A == 44) // 'J'
					{
						//if (debug) printf("J -> J J+1\n");
						Insert(d.X+1, d.A+1, mem59, d.stress[d.X]);
						pos++;
						break;
					}
					
				}
			// Jump here to continue 
			//pos41812:
				if (skipSteps < 10) {
					skipSteps = 0;

			// RULE: Soften T following vowel
			// NOTE: This rule fails for cases such as "ODD"
			//       <UNSTRESSED VOWEL> T <PAUSE> -> <UNSTRESSED VOWEL> DX <PAUSE>
			//       <UNSTRESSED VOWEL> D <PAUSE>  -> <UNSTRESSED VOWEL> DX <PAUSE>
			// Example: PARTY, TARDY


			// Past this point, only process if phoneme is T or D
					 
					if (d.A != 69)    // 'T'
					if (d.A != 57) {pos++; break;}       // 'D'
					//pos41825:


			// If prior phoneme is not a vowel, continue processing phonemes
					if ((SamTabs.flags[d.phonemeIndex[d.X-1]] & 128) == 0) {pos++; break;}
					
			// Get next phoneme
					d.X++;
					d.X = d.X % 256;
					d.A = d.phonemeIndex[d.X];
					//pos41841
			// Is the next phoneme a pause?
					if (d.A != 0)
					{
			// If next phoneme is not a pause, continue processing phonemes
						if ((SamTabs.flags[d.A] & 128) == 0) {pos++; break;}
			// If next phoneme is stressed, continue processing phonemes
			// FIXME: How does a pause get stressed?
						if (d.stress[d.X] != 0) {pos++; break;}
			//pos41856:
			// Set phonemes to DX
						//if (debug) printf("RULE: Soften T or D following vowel or ER and preceding a pause -> DX\n");
						d.phonemeIndex[pos] = 30;       // 'DX'
					} else
					{
						d.A = d.phonemeIndex[d.X+1];
						if (d.A == 255) //prevent buffer overflow
							d.A = 65 & 128;
						else
			// Is next phoneme a vowel or ER?
							d.A = SamTabs.flags[d.A] & 128;
						//if (debug) if (d.A != 0) printf("RULE: Soften T or D following vowel or ER and preceding a pause -> DX\n");
						if (d.A != 0) d.phonemeIndex[pos] = 30;  // 'DX'
					}

					pos++;
				}
				break;
			}
			
			if (breakOut) {
				continue;	
			}
			
		} // while
	}
	
	function Insert(position:Int/*char var57*/, mem60:Int/*char*/, mem59:Int/*char*/, mem58:Int /*char*/) {
		var i = 253;
		//for(i=253; i >= position; i--) // ML : always keep last safe-guarding 255	
		while(i >= position)
		{
			d.phonemeIndex[i+1] = d.phonemeIndex[i];
			d.phonemeLength[i+1] = d.phonemeLength[i];
			d.stress[i + 1] = d.stress[i];
			i--;
		}

		d.phonemeIndex[position] = mem60;
		d.phonemeLength[position] = mem59;
		d.stress[position] = mem58;
		return;
	}
	
	function CopyStress():Void {
		// loop thought all the phonemes to be output
		var pos = 0; //mem66 char
		while(true) {
			// get the phomene
			d.Y = d.phonemeIndex[pos];
			
			// exit at end of buffer
			if (d.Y == 255) return;
			
			// if CONSONANT_FLAG set, skip - only vowels get d.stress
			if ((SamTabs.flags[d.Y] & 64) == 0) {pos++; continue;}
			// get the next phoneme
			d.Y = d.phonemeIndex[pos+1];
			if (d.Y == 255) //prevent buffer overflow
			{
				pos++;
				pos = pos % 256;
				continue;
			} else
			// if the following phoneme is a vowel, skip
			if ((SamTabs.flags[d.Y] & 128) == 0)  {
				pos++;
				pos = pos % 256;
				continue;
			}

			// get the d.stress value at the next position
			d.Y = d.stress[pos + 1];
			
			// if next phoneme is not stressed, skip
			if (d.Y == 0)  {
				pos++;
				pos = pos % 256;
				continue;
			}

			// if next phoneme is not a VOWEL OR ER, skip
			if ((d.Y & 128) != 0)  {
				pos++; 
				pos = pos % 256;
				continue;
			}

			// copy d.stress from prior phoneme to this one
			d.stress[pos] = d.Y + 1;
			
			// advance pointer
			pos++;
			pos = pos % 256;
		}
	}
	
	function SetPhonemeLength() {
		var A:Int; //Char
		var position:Int = 0;
		while(d.phonemeIndex[position] != 255 ) {
			A = d.stress[position];
			//41218: BMI 41229
			if ((A == 0) || ((A&128) != 0)) {
				d.phonemeLength[position] = SamTabs.phonemeLengthTable[d.phonemeIndex[position]];
			} else {
				d.phonemeLength[position] = SamTabs.phonemeStressedLengthTable[d.phonemeIndex[position]];
			}
			position++;
		}
	}
	
	function AdjustLengths():Void {

		// LENGTHEN VOWELS PRECEDING PUNCTUATION
		//
		// Search for punctuation. If found, back up to the first vowel, then
		// process all phonemes between there and up to (but not including) the punctuation.
		// If any phoneme is found that is a either a fricative or voiced, the duration is
		// increased by (length * 1.5) + 1

		// loop index
		d.X = 0;
		var index:Int;//unsigned char

		// iterate through the phoneme list
		var loopIndex:Int = 0;//unsigned char
		while(true) {
			// get a phoneme
			index = d.phonemeIndex[d.X];
			
			// exit loop if end on buffer token
			if (index == 255) {
				break;
			}

			// not punctuation?
			if((SamTabs.flags2[index] & 1) == 0) {
				// skip
				d.X++;
				d.X = d.X % 256;
				continue;
			}
			
			// hold index
			loopIndex = d.X;
			
			// Loop backwards from this point
	//pos48644:
			var megaBreak = false;
			while(true){
				 
				// back up one phoneme
				d.X--;
				
				// stop once the beginning is reached
				if (d.X == 0) {
					megaBreak = true;
					break;
				}
				
				// get the preceding phoneme
				index = d.phonemeIndex[d.X];

				if (index != 255) //inserted to prevent access overrun
				if ((SamTabs.flags[index] & 128) == 0) {
					//goto pos48644; // if not a vowel, continue looping
					continue;
				}else {
					break;	
				}
			}
			
			if (megaBreak) {
				break;	
			}

			//pos48657:
			do
			{
				// test for vowel
				index = d.phonemeIndex[d.X];

				if (index != 255)//inserted to prevent access overrun
				// test for fricative/unvoiced or not voiced
				if(((SamTabs.flags2[index] & 32) == 0) || ((SamTabs.flags[index] & 4) != 0))     //nochmal überprüfen
				{
					//A = flags[Y] & 4;
					//if(A == 0) goto pos48688;
									
					// get the phoneme length
					d.A = d.phonemeLength[d.X];

					// change phoneme length to (length * 1.5) + 1
					d.A = (d.A >> 1) + d.A + 1;
					d.A = d.A % 256;
	//if (debug) printf("RULE: Lengthen <FRICATIVE> or <VOICED> between <VOWEL> and <PUNCTUATION> by 1.5\n");
	//if (debug) printf("PRE\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[d.X]], signInputTable2[d.phonemeIndex[d.X]], phonemeLength[d.X]);

					d.phonemeLength[d.X] = d.A;
					
	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[d.X]], signInputTable2[d.phonemeIndex[d.X]], phonemeLength[d.X]);

				}
				// keep moving forward
				d.X++;
				d.X = d.X % 256;
			} while (d.X != loopIndex);
			//	if (d.X != loopIndex) goto pos48657;
			d.X++;
			d.X = d.X % 256;
		}  // while

		// Similar to the above routine, but shorten vowels under some circumstances

		// Loop throught all phonemes
		loopIndex = 0;
		//pos48697

		while(true) {
			// get a phoneme
			d.X = loopIndex;
			index = d.phonemeIndex[d.X];
			
			// exit routine at end token
			if (index == 255) return;

			// vowel?
			d.A = SamTabs.flags[index] & 128;
			if (d.A != 0) {
				// get next phoneme
				d.X++;
				d.X = d.X % 256;
				index = d.phonemeIndex[d.X];
				
				// get flags
				if (index == 255) 
					d.mem56 = 65; // use if end marker
				else
					d.mem56 = SamTabs.flags[index];

				// not a consonant
				if ((SamTabs.flags[index] & 64) == 0) {
					// RX or LX?
					if ((index == 18) || (index == 19))  // 'RX' & 'LX'
					{
						// get the next phoneme
						d.X++;
						d.X = d.X % 256;
						index = d.phonemeIndex[d.X];
						
						// next phoneme a consonant?
						if ((SamTabs.flags[index] & 64) != 0) {
							// RULE: <VOWEL> RX | LX <CONSONANT>
							
							
	//if (debug) printf("RULE: <VOWEL> <RX | LX> <CONSONANT> - decrease length by 1\n");
	//if (debug) printf("PRE\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", loopIndex, signInputTable1[d.phonemeIndex[loopIndex]], signInputTable2[d.phonemeIndex[loopIndex]], phonemeLength[loopIndex]);
							
							// decrease length of vowel by 1 frame
							d.phonemeLength[loopIndex] = d.phonemeLength[loopIndex] - 1;

	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", loopIndex, signInputTable1[d.phonemeIndex[loopIndex]], signInputTable2[d.phonemeIndex[loopIndex]], phonemeLength[loopIndex]);

						}
						// move ahead
						loopIndex++;
						continue;
					}
					// move ahead
					loopIndex++;
					continue;
				}
				
				
				// Got here if not <VOWEL>

				// not voiced
				if ((d.mem56 & 4) == 0)
				{
						   
					 // Unvoiced 
					 // *, .*, ?*, ,*, -*, DX, S*, SH, F*, TH, /H, /X, CH, P*, T*, K*, KX
					 
					// not an unvoiced plosive?
					if((d.mem56 & 1) == 0) {
						// move ahead
						loopIndex++; 
						continue;
					}

					// P*, T*, K*, KX

					
					// RULE: <VOWEL> <UNVOICED PLOSIVE>
					// <VOWEL> <P*, T*, K*, KX>
					
					// move back
					d.X--;
					if (d.X < 0) {
						d.X += 256;
					}
					
	//if (debug) printf("RULE: <VOWEL> <UNVOICED PLOSIVE> - decrease vowel by 1/8th\n");
	//if (debug) printf("PRE\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", X, signInputTable1[d.phonemeIndex[X]], signInputTable2[d.phonemeIndex[X]],  phonemeLength[X]);

					// decrease length by 1/8th
					d.mem56 = d.phonemeLength[d.X] >> 3;
					d.phonemeLength[d.X] -= d.mem56;

	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[d.X]], signInputTable2[d.phonemeIndex[d.X]], phonemeLength[d.X]);

					// move ahead
					loopIndex++;
					continue;
				}

				// RULE: <VOWEL> <VOICED CONSONANT>
				// <VOWEL> <WH, R*, L*, W*, Y*, M*, N*, NX, DX, Q*, Z*, ZH, V*, DH, J*, B*, D*, G*, GX>

	//if (debug) printf("RULE: <VOWEL> <VOICED CONSONANT> - increase vowel by 1/2 + 1\n");
	//if (debug) printf("PRE\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X-1, signInputTable1[d.phonemeIndex[d.X-1]], signInputTable2[d.phonemeIndex[d.X-1]],  phonemeLength[d.X-1]);

				// decrease length
				d.A = d.phonemeLength[d.X-1];
				d.phonemeLength[d.X-1] = (d.A >> 2) + d.A + 1;     // 5/4*A + 1
				d.phonemeLength[d.X - 1] = d.phonemeLength[d.X - 1] % 256;
	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X-1, signInputTable1[d.phonemeIndex[d.X-1]], signInputTable2[d.phonemeIndex[d.X-1]], phonemeLength[d.X-1]);

				// move ahead
				loopIndex++;
				continue;
				
			}


			// WH, R*, L*, W*, Y*, M*, N*, NX, Q*, Z*, ZH, V*, DH, J*, B*, D*, G*, GX

	//pos48821:
			   
			// RULE: <NASAL> <STOP CONSONANT>
			//       Set punctuation length to 6
			//       Set stop consonant length to 5
			   
			// nasal?
			if((SamTabs.flags2[index] & 8) != 0) {
							  
				// M*, N*, NX, 

				// get the next phoneme
				d.X++;
				d.X = d.X % 256;
				index = d.phonemeIndex[d.X];

				// end of buffer?
				if (index == 255)
				   d.A = 65&2;  //prevent buffer overflow
				else
					d.A = SamTabs.flags[index] & 2; // check for stop consonant


				// is next phoneme a stop consonant?
				if (d.A != 0)
				
				   // B*, D*, G*, GX, P*, T*, K*, KX

				{
	//if (debug) printf("RULE: <NASAL> <STOP CONSONANT> - set nasal = 5, consonant = 6\n");
	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[d.X]], signInputTable2[d.phonemeIndex[d.X]], phonemeLength[d.X]);
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X-1, signInputTable1[d.phonemeIndex[d.X-1]], signInputTable2[d.phonemeIndex[d.X-1]], phonemeLength[d.X-1]);

					// set stop consonant length to 6
					d.phonemeLength[d.X] = 6;
					
					// set nasal length to 5
					d.phonemeLength[d.X-1] = 5;
					
	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[X]], signInputTable2[d.phonemeIndex[X]], phonemeLength[X]);
	//if (debug) printf("phoneme %d (%c%c) length %d\n", X-1, signInputTable1[d.phonemeIndex[X-1]], signInputTable2[d.phonemeIndex[X-1]], phonemeLength[X-1]);

				}
				// move to next phoneme
				loopIndex++;
				continue;
			}


			// WH, R*, L*, W*, Y*, Q*, Z*, ZH, V*, DH, J*, B*, D*, G*, GX

			// RULE: <VOICED STOP CONSONANT> {optional silence} <STOP CONSONANT>
			//       Shorten both to (length/2 + 1)

			// (voiced) stop consonant?
			if((SamTabs.flags[index] & 2) != 0) {                         
				// B*, D*, G*, GX
							 
				// move past silence
				do {
					// move ahead
					d.X++;
					d.X = d.X % 256;
					index = d.phonemeIndex[d.X];
				} while(index == 0);


				// check for end of buffer
				if (index == 255) //buffer overflow
				{
					// ignore, overflow code
					if ((65 & 2) == 0) {loopIndex++; continue;}
				} else if ((SamTabs.flags[index] & 2) == 0) {
					// if another stop consonant, move ahead
					loopIndex++;
					continue;
				}

				// RULE: <UNVOICED STOP CONSONANT> {optional silence} <STOP CONSONANT>
				//if (debug) printf("RULE: <UNVOICED STOP CONSONANT> {optional silence} <STOP CONSONANT> - shorten both to 1/2 + 1\n");
				//if (debug) printf("PRE\n");
				//if (debug) printf("phoneme %d (%c%c) length %d\n", X, signInputTable1[d.phonemeIndex[X]], signInputTable2[d.phonemeIndex[X]], phonemeLength[X]);
				//if (debug) printf("phoneme %d (%c%c) length %d\n", X-1, signInputTable1[d.phonemeIndex[X-1]], signInputTable2[d.phonemeIndex[X-1]], phonemeLength[X-1]);
	// X gets overwritten, so hold prior X value for debug statement
				//int debugX = X;
				// shorten the prior phoneme length to (length/2 + 1)
				d.phonemeLength[d.X] = (d.phonemeLength[d.X] >> 1) + 1;
				d.X = loopIndex;

				// also shorten this phoneme length to (length/2 +1)
				d.phonemeLength[loopIndex] = (d.phonemeLength[loopIndex] >> 1) + 1;

	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", debugX, signInputTable1[d.phonemeIndex[debugX]], signInputTable2[d.phonemeIndex[debugX]], phonemeLength[debugX]);
	//if (debug) printf("phoneme %d (%c%c) length %d\n", debugX-1, signInputTable1[d.phonemeIndex[debugX-1]], signInputTable2[d.phonemeIndex[debugX-1]], phonemeLength[debugX-1]);


				// move ahead
				loopIndex++;
				continue;
			}


			// WH, R*, L*, W*, Y*, Q*, Z*, ZH, V*, DH, J*, **, 

			// RULE: <VOICED NON-VOWEL> <DIPHTONG>
			//       Decrease <DIPHTONG> by 2

			// liquic consonant?
			if ((SamTabs.flags2[index] & 16) != 0)
			{
				// R*, L*, W*, Y*
							   
				// get the prior phoneme
				index = d.phonemeIndex[d.X-1];

				// prior phoneme a stop consonant>
				if((SamTabs.flags[index] & 2) != 0)
								 // Rule: <LIQUID CONSONANT> <DIPHTONG>

	//if (debug) printf("RULE: <LIQUID CONSONANT> <DIPHTONG> - decrease by 2\n");
	//if (debug) printf("PRE\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", X, signInputTable1[d.phonemeIndex[X]], signInputTable2[d.phonemeIndex[X]], phonemeLength[X]);
				 
				 // decrease the phoneme length by 2 frames (20 ms)
				 d.phonemeLength[d.X] -= 2;

	//if (debug) printf("POST\n");
	//if (debug) printf("phoneme %d (%c%c) length %d\n", d.X, signInputTable1[d.phonemeIndex[X]], signInputTable2[d.phonemeIndex[X]], phonemeLength[X]);
			 }

			 // move to next phoneme
			 loopIndex++;
			 continue;
		}
	//            goto pos48701;
	}
	
	function Code41240():Void {
		var pos:Int = 0; //Char

		while(d.phonemeIndex[pos] != 255) {
			var index; //register AC
			d.X = pos;
			index = d.phonemeIndex[pos];
			if ((SamTabs.flags[index]&2) == 0)
			{
				pos++;
				pos = pos % 256;
				continue;
			} else
			if ((SamTabs.flags[index]&1) == 0)
			{
				Insert(pos+1, index+1, SamTabs.phonemeLengthTable[index+1], d.stress[pos]);
				Insert(pos+2, index+2, SamTabs.phonemeLengthTable[index+2], d.stress[pos]);
				pos += 3;
				pos = pos % 256;
				continue;
			}

			do
			{
				d.X++;
				d.X = d.X % 256;
				d.A = d.phonemeIndex[d.X];
			} while(d.A==0);

			if (d.A != 255) {
				if ((SamTabs.flags[d.A] & 8) != 0)  {
					pos++;
					pos = pos % 256;
					continue;
				}
				if ((d.A == 36) || (d.A == 37)) {
					pos++;
					pos = pos % 256;
					continue;
				}// '/H' '/d.X'
			}

			Insert(pos+1, index+1, SamTabs.phonemeLengthTable[index+1], d.stress[pos]);
			Insert(pos+2, index+2, SamTabs.phonemeLengthTable[index+2], d.stress[pos]);
			pos += 3;
			pos = pos % 256;
		};
	}
	
	function InsertBreath():Void {
		var mem54:Int;//Char
		var mem55:Int;//Char
		var index:Int; //variable Y//Char
		mem54 = 255;
		d.X++;
		d.X = d.X % 256;
		mem55 = 0;
		var mem66:Int = 0;//Char
		while(true) {
			//pos48440:
			d.X = mem66;
			index = d.phonemeIndex[d.X];
			if (index == 255) {
				return;
			}
			
			mem55 += d.phonemeLength[d.X];
			mem55 = mem55 % 256;

			if (mem55 < 232) {
				if (index != 254) // ML : Prevents an index out of bounds problem		
				{
					d.A = SamTabs.flags2[index]&1;
					if(d.A != 0) {
						d.X++;
						d.X = d.X % 256;
						mem55 = 0;
						Insert(d.X, 254, mem59, 0);
						mem66++;
						mem66++;
						mem66 = mem66 % 256;
						continue;
					}
				}
				if (index == 0) {
					mem54 = d.X;
				}
				mem66++;
				mem66 = mem66 % 256;
				continue;
			}
			
			d.X = mem54;
			d.phonemeIndex[d.X] = 31;   // 'Q*' glottal stop
			d.phonemeLength[d.X] = 4;
			d.stress[d.X] = 0;
			d.X++;
			d.X = d.X % 256;
			mem55 = 0;
			Insert(d.X, 254, mem59, 0);
			d.X++;
			d.X = d.X % 256;
			mem66 = d.X;
		}

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
		var length = Sam.buffer.length;//44100*10;
		var data:Vector<Float> = new Vector<Float>(length << 2);
		var i2 = 0;
		for (i in 0...length) {
			var f:Float = Sam.buffer[i];
			f /= 256.0;
			f -= 0.5;
			data[i * 4] = f;
			data[i * 4 + 1] = f;
			data[i * 4 + 2] = f;
			data[i * 4 + 3] = f;
			//data[i] =  (Math.sin((i / (300.0 + Math.sin(i * 0.001) * 99))) * 0.5 + 0.5) / Math.pow(i * 0.0001, 3) ;
		
		}
		
		var d = data.toArray();
		d.splice(i2, d.length - i2);
		
		//trace(d);
		
		return new SamSound(data);
	}
}