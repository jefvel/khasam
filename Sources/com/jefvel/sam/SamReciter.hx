package com.jefvel.sam;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Int32Array;

/**
 * ...
 * @author jefvel
 */
class SamReciter
{
	
	static var A:Int;
	static var X:Int;
	static var Y:Int;

	static var inputtemp:Vector<Int> = new Vector<Int>(256);   // secure copy of input tab36096

	public static var result:Vector<Int>;
	
	static function Code37055(mem59:Int):Void {
		X = mem59;
		X--;
		A = inputtemp[X];
		Y = A;
		A = ReciterTabs.tab36376[Y];
		return;
	}
	
	static function Code37066(mem58:Int):Void {
		X = mem58;
		X++;
		X = X % 256;
		A = inputtemp[X];
		Y = A;
		A = ReciterTabs.tab36376[Y];
	}
	
	static function GetRuleByte(mem62:Int, Y:Int):Int {
		var address:Int = mem62;
		if (mem62 >= 37541) {
			address -= 37541;
			return ReciterTabs.rules2[address+Y];
		}
		
		address -= 32000;
		return ReciterTabs.rules[address+Y];
	}
	
	static function stringToArray(input:String) {
		var res = new Vector<Int>(input.length + 1);
		for (i in 0...input.length) {
			input = input.toUpperCase();
			res[i] = input.charCodeAt(i);
		}
		res[res.length - 1] = 0;
		result = res;
		trace("Input string: " + res);
		return res;
	}
	
	public static function textToPhonemes(str:String) {
		var input = stringToArray(str);
		trace(input);
		
		var mem56:Int = 0;      //output position for phonemes
		var mem57:Int = 0;
		var mem58:Int = 0;
		var mem59:Int = 0;
		var mem60:Int = 0;
		var mem61:Int = 0;
		var mem62:Int = 0;     // memory position of current rule

		var mem64:Int = 0;      // position of '=' or current character
		var mem65:Int = 0;     // position of ')'
		var mem66:Int = 0;     // position of '('
		var mem36653:Int = 0;

		inputtemp[0] = 32;

		// secure copy of input
		// because input will be overwritten by phonemes
		X = 1;
		Y = 0;
		do {
			//pos36499:
			A = input[Y] & 127;
			if ( A >= 112) {
				A = A & 95;
			}else if ( A >= 96) {
				A = A & 79;
			}
			
			inputtemp[X] = A;
			X++;
			Y++;
		} while (Y != 255);


		X = 255;
		inputtemp[X] = 27;
		mem61 = 255;
		
		var maxSkip = 0;
		var skipFlag = maxSkip;
		var runs = 0;

		while(true) {
			runs ++;
			
		//pos36550:
			if (skipFlag <= 2) {
				trace("pos36550");
				skipFlag = maxSkip;
				A = 255;
				mem56 = 255;
			}
			
		//pos36554:
			if (skipFlag <= 3) {
				trace("pos36554");
				skipFlag = maxSkip;
				while(true) {
					mem61++;
					mem61 = mem61 % 256;
					X = mem61;
					A = inputtemp[X];
					mem64 = A;
					if (A == '['.charCodeAt(0)) {
						mem56++;
						mem56 = mem56 % 256;
						X = mem56;
						A = 155;
						input[X] = 155;
						//goto pos36542;
						//			Code39771(); 	//Code39777();
						return 1;
					}

					//pos36579:
					if (A != '.'.charCodeAt(0)) {
						break;
					}
					
					X++;
					X = X % 256;
					Y = inputtemp[X];
					A = ReciterTabs.tab36376[Y] & 1;
					
					if (A != 0) {
						break;
					}
					
					mem56++;
					mem56 = mem56 % 256;
					X = mem56;
					A = '.'.charCodeAt(0);
					input[X] = '.'.charCodeAt(0);
				} //while


				//pos36607:
				A = mem64;
				Y = A;
				A = ReciterTabs.tab36376[A];
				mem57 = A;
				if((A&2) != 0)
				{
					mem62 = 37541;
					//goto pos36700;
					skipFlag = 6;
					continue;
				}

				//pos36630:
				A = mem57;
				if (A != 0) {
					//goto pos36677;
					skipFlag = 5;
					continue;
				}
				A = 32;
				inputtemp[X] = ' '.charCodeAt(0);
				mem56++;
				mem56 = mem56 % 256;
				X = mem56;
				if (X > 120) {
					//goto pos36654;
					skipFlag = 4;
					continue;
				}
				input[X] = A;
				//goto pos36554;
				skipFlag = 3;
				continue;
			}
			// -----

			//36653 is unknown. Contains position
			//pos36654:
			if (skipFlag <= 4) {
				trace("pos36654");
				skipFlag = maxSkip;
				input[X] = 155;
				A = mem61;
				mem36653 = A;
				//	mem29 = A; // not used
				//	Code36538(); das ist eigentlich
				return runs;
				//Code39771();
				//go on if there is more input ???
				mem61 = mem36653;
				//goto pos36550;
				skipFlag = 2;
				continue;
			}

		//pos36677:
			if (skipFlag <= 5) {
				trace("pos36677");
				skipFlag = maxSkip;
				A = mem57 & 128;
				A = A % 256;
				if(A == 0) {
					//36683: BRK
					return runs;
				}

				// go to the right rules for this character.
				X = mem64 - 'A'.charCodeAt(0);
				mem62 = ReciterTabs.tab37489[X] | (ReciterTabs.tab37515[X] << 8);
				mem62 = mem62 % 65536;
			}
			
			// -------------------------------------
			// go to next rule
			// -------------------------------------

		//pos36700:
			if (skipFlag <= 6) {
				trace("pos36700");

				skipFlag = maxSkip;	
				// find next rule
				Y = 0;
				do {
					mem62 += 1;
					mem62 = mem62 % 65536;
					A = GetRuleByte(mem62, Y);
				} while ((A & 128) == 0);
				
				Y++;
				Y = Y % 256;

				//pos36720:
				// find '('
				while(true) {
					A = GetRuleByte(mem62, Y);
					if (A == '('.charCodeAt(0)) break;
					Y++;
					Y = Y % 256;
				}
				mem66 = Y;

				//pos36732:
				// find ')'
				do {
					Y++;
					Y = Y % 256;
					A = GetRuleByte(mem62, Y);
				} while(A != ')'.charCodeAt(0));
				mem65 = Y;

				//pos36741:
				// find '='
				do {
					Y++;
					Y = Y % 256;
					A = GetRuleByte(mem62, Y);
					A = A & 127;
				} while (A != '='.charCodeAt(0));
				mem64 = Y;
				
				X = mem61;
				mem60 = X;

				// compare the string within the bracket
				Y = mem66;
				Y++;
				Y = Y % 256;
				var superBreak = false;
				//pos36759:
				while(true) {
					mem57 = inputtemp[X];
					A = GetRuleByte(mem62, Y);
					if (A != mem57) {
						//goto pos36700;
						skipFlag = 6;
						superBreak = true;
						break;
					}
					Y++;
					Y = Y % 256;
					if (Y == mem65) {
						break;
					}
					X++;
					X = X % 256;
					mem60 = X;
				}
				if (superBreak) {
					continue;	
				}
			
		// the string in the bracket is correct

		//pos36787:
			A = mem61;
			mem59 = mem61;
		}
		//pos36791:
			if (skipFlag <= 7) {
				trace("pos36791");
				skipFlag = maxSkip;
				var superBreak = false;
				while (true) {
					mem66--;
					if (mem66 < 0) {
						mem66 = 255;
					}
					
					Y = mem66;
					A = GetRuleByte(mem62, Y);
					mem57 = A;
					//36800: BPL 36805
					if ((A & 128) != 0) {
						//goto pos37180;
						skipFlag = 24;
						superBreak = true;
						break;
					}
					X = A & 127;
					A = ReciterTabs.tab36376[X] & 128;
					if (A == 0) {
						break;
					}
					
					X = mem59 - 1;
					if (X < 0) {
						X = 255;
					}
					
					A = inputtemp[X];
					if (A != mem57) {
						//goto pos36700;
						skipFlag = 6;
						superBreak = true;
						break;
					}
					
					mem59 = X;
				}
				
				if (superBreak) {
					continue;
				}
				

			//pos36833:
				A = mem57;
				if (A == ' '.charCodeAt(0)) {
					//goto pos36895;
					skipFlag = 8;
					continue;
				}
				if (A == '#'.charCodeAt(0)) {
					//goto pos36910;
					skipFlag = 10;
					continue;
				}
				if (A == '.'.charCodeAt(0)) {
					//goto pos36920;
					skipFlag = 11;
					continue;
				}
				if (A == '&'.charCodeAt(0)) {
					//goto pos36935;
					skipFlag = 13;
					continue;
				}
				if (A == '@'.charCodeAt(0)) {
					//goto pos36967;
					skipFlag = 14;
					continue;
				}
				if (A == '^'.charCodeAt(0)) {
					//goto pos37004;
					skipFlag = 15;
					continue;
				}
				if (A == '+'.charCodeAt(0)) {
					//goto pos37019;
					skipFlag = 17;
					continue;
				}
				if (A == ':'.charCodeAt(0)) {
					//goto pos37040;
					skipFlag = 18;
					continue;
				}
				//	Code42041();    //Error
				//36894: BRK
				return -2;
			}
			// --------------
			
			//pos36895:
			if (skipFlag <= 8) {
				trace("pos36895");
				skipFlag = maxSkip;
				Code37055(mem59);
				A = A & 128;
				if (A != 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}
			
			//pos36905:
			if (skipFlag <= 9) {
				trace("pos36905");
				skipFlag = maxSkip;	
				mem59 = X;
				//goto pos36791;
				skipFlag = 7;
				continue;
			}

			// --------------

		//pos36910:
			if (skipFlag <= 10) {
				trace("pos36910");
				skipFlag = maxSkip;
				
				Code37055(mem59);
				A = A & 64;
				if (A != 0) {
					//goto pos36905;
					skipFlag = 9;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}

			// --------------


		//pos36920:
			if (skipFlag <= 11) {
				trace("pos36920");
				skipFlag = maxSkip;
				Code37055(mem59);
				A = A & 8;
				if (A == 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}
		//pos36930:
			if (skipFlag <= 12) {
				trace("pos36930");
				skipFlag = maxSkip;
				mem59 = X;
				//goto pos36791;
				skipFlag = 7;
				continue;
			}

			// --------------

		//pos36935:
			if (skipFlag <= 13) {
				trace("pos36935");
				skipFlag = maxSkip;
				Code37055(mem59);
				A = A & 16;
				if (A != 0) {
					//goto pos36930;
					skipFlag = 12;
					continue;
				}
				A = inputtemp[X];
				if (A != 72) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				X--;
				if (X < 0) {
					X = 255;
				}
				
				A = inputtemp[X];
				if ((A == 67) || (A == 83)) {
					//goto pos36930;
					skipFlag = 12;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}
			// --------------

		//pos36967:
			if (skipFlag <= 14) {
				trace("pos36967");
				skipFlag = maxSkip;
				Code37055(mem59);
				A = A & 4;
				if (A != 0) {
					//goto pos36930;
					skipFlag = 12;
					continue;
				}
				A = inputtemp[X];
				if (A != 72) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				if ((A != 84) && (A != 67) && (A != 83)) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				mem59 = X;
				
				//goto pos36791;
				skipFlag = 7;
				continue;
			}

			// --------------


		//pos37004:
			if (skipFlag <= 15) {
				trace("pos37004");
				skipFlag = maxSkip;	
				Code37055(mem59);
				A = A & 32;
				if (A == 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}

		//pos37014:
			if (skipFlag <= 16) {
				skipFlag = maxSkip;
				mem59 = X;
				
				//goto pos36791;
				skipFlag = 7;
				continue;
			}

			// --------------

		//pos37019:
			if (skipFlag <= 18) {
				skipFlag = maxSkip;	
				X = mem59;
				X--;
				if (X < 0) {
					X = 255;
				}
				A = inputtemp[X];
				if ((A == 'E'.charCodeAt(0)) || (A == 'I'.charCodeAt(0)) || (A == 'Y'.charCodeAt(0))) {
					//goto pos37014;
					skipFlag = 16;
					continue;
				}
				//goto pos36700;
				skipFlag = 6;
				continue;
			}
			// --------------

		//pos37040:
			if (skipFlag <= 19) {
				skipFlag = maxSkip;	
				Code37055(mem59);
				A = A & 32;
				if (A == 0) {
					//goto pos36791;
					skipFlag = 7;
					continue;
				}
				mem59 = X;
				
				//goto pos37040;
				skipFlag = 18;
				continue;
			}

		//---------------------------------------


		//pos37077:
			if (skipFlag <= 20) {
				skipFlag = maxSkip;	
				X = mem58 + 1;
				X = X % 256;
				
				A = inputtemp[X];
				if (A != 'E'.charCodeAt(0)) {
					//goto pos37157;
					skipFlag = 23;
					continue;
				}
				X++;
				X = X % 256;
				Y = inputtemp[X];
				X--;
				if (X < 0) {
					X = 255;
				}
				A = ReciterTabs.tab36376[Y] & 128;
				if (A == 0) {
					//goto pos37108;
					skipFlag = 20;
					continue;
				}
				X++;
				X = X % 256;
				A = inputtemp[X];
				if (A != 'R'.charCodeAt(0)) {
					//goto pos37113;
					skipFlag = 21;
					continue;
				}
			}
		//pos37108:
			if (skipFlag <= 21) {
				skipFlag = maxSkip;	
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}
		//pos37113:
			if (skipFlag <= 22) {
				skipFlag = maxSkip;	
				if ((A == 83) || (A == 68)) {
					//goto pos37108;  // 'S' 'D'
					skipFlag = 20;
					continue;
				}
				if (A != 76) {
					//goto pos37135; // 'L'
					skipFlag = 22;
					continue;
				}
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if (A != 89) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				//goto pos37108;
				skipFlag = 20;
				continue;
			}
			
		//pos37135:
			if (skipFlag <= 23) {
				skipFlag = maxSkip;
				if (A != 70) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if (A != 85) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if (A == 76) {
					//goto pos37108;
					skipFlag = 20;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}

		//pos37157:
			if (skipFlag <= 23) {
				skipFlag = maxSkip;
				if (A != 73) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if (A != 78) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if (A == 71) {
					//goto pos37108;
					skipFlag = 20;
					continue;
				}
				//pos37177:
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}
			// -----------------------------------------

		//pos37180:
			if (skipFlag <= 24) {
				skipFlag = maxSkip;
				A = mem60;
				mem58 = A;
			}

		//pos37184:
			if (skipFlag <= 25) {
				skipFlag = maxSkip;
				Y = mem65 + 1;
				Y = Y % 256;

				//37187: CPY 64
				//	if(? != 0) goto pos37194;
				if (Y == mem64) {
					//goto pos37455;
					skipFlag = 38;
					continue;
				}
				mem65 = Y;
				//37196: LDA (62),y
				A = GetRuleByte(mem62, Y);
				mem57 = A;
				X = A;
				A = ReciterTabs.tab36376[X] & 128;
				if (A == 0) {
					//goto pos37226;
					skipFlag = 26;
					continue;
				}
				X = mem58 + 1;
				X = X % 256;
				
				A = inputtemp[X];
				if (A != mem57) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}
		//pos37226:
			if (skipFlag <= 26) {
				skipFlag = maxSkip;
				A = mem57;
				if (A == 32) {
					//goto pos37295;   // ' '
					skipFlag = 27;
					continue;
				}
				if (A == 35) {
					//goto pos37310;   // '#'
					skipFlag = 29;
					continue;
				}
				if (A == 46) {
					//goto pos37320;   // '.'
					skipFlag = 30;
					continue;
				}
				if (A == 38) {
					//goto pos37335;   // '&'
					skipFlag = 32;
					continue;
				}
				if (A == 64) {
					//goto pos37367;   // ''
					skipFlag = 33;
					continue;
				}
				if (A == 94) {
					//goto pos37404;   // ''
					skipFlag = 34;
					continue;
				}
				if (A == 43) {
					//goto pos37419;   // '+'
					skipFlag = 36;
					continue;
				}
				if (A == 58) {
					//goto pos37440;   // ':'
					skipFlag = 37;
					continue;
				}
				if (A == 37) {
					//goto pos37077;   // '%'
					skipFlag = 19;
					continue;
				}
				//pos37291:
				//	Code42041(); //Error
				//37294: BRK
				return -3;
			}

			// --------------
		//pos37295:
			if (skipFlag <= 27) {
				skipFlag = maxSkip;
				Code37066(mem58);
				A = A & 128;
				if (A != 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}
		//pos37305:
			if (skipFlag <= 28) {
				skipFlag = maxSkip;
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}

			// --------------

		//pos37310:
			if (skipFlag <= 29) {
				skipFlag = maxSkip;
				Code37066(mem58);
				A = A & 64;
				if (A != 0) {
					//goto pos37305;
					skipFlag = 28;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}

			// --------------


		//pos37320:
			if (skipFlag <= 30) {
				skipFlag = maxSkip;	
				Code37066(mem58);
				A = A & 8;
				if (A == 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}

		//pos37330:
			if(skipFlag <= 31) {
				skipFlag = maxSkip;
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}
			
			// --------------

		//pos37335:
			if (skipFlag <= 32) {
				skipFlag = maxSkip;
				Code37066(mem58);
				A = A & 16;
				if (A != 0) {
					//goto pos37330;
					skipFlag = 31;
					continue;
				}
				A = inputtemp[X];
				if (A != 72) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				
				X++;
				X = X % 256;
				
				A = inputtemp[X];
				if ((A == 67) || (A == 83)) {
					//goto pos37330;
					skipFlag = 31;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}

			// --------------


		//pos37367:
			if (skipFlag <= 33) {
				skipFlag = maxSkip;
				Code37066(mem58);
				A = A & 4;
				if (A != 0) {
					//goto pos37330;
					skipFlag = 31;
					continue;
				}
				A = inputtemp[X];
				if (A != 72) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				if ((A != 84) && (A != 67) && (A != 83)) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}

			// --------------

		//pos37404:
			if (skipFlag <= 34) {
				skipFlag = maxSkip;	
				Code37066(mem58);
				A = A & 32;
				if (A == 0) {
					//goto pos36700;
					skipFlag = 6;
					continue;
				}
			}
		//pos37414:
			if (skipFlag <= 35) {
				skipFlag = maxSkip;
				mem58 = X;
				//goto pos37184;
				skipFlag = 25;
				continue;
			}
			

			// --------------
			
		//pos37419:
			if (skipFlag <= 36) {
				skipFlag = maxSkip;	
				X = mem58;
				X++;
				X = X % 256;
				A = inputtemp[X];
				if ((A == 69) || (A == 73) || (A == 89)) {
					//goto pos37414;
					skipFlag = 35;
					continue;
				}
				
				//goto pos36700;
				skipFlag = 6;
				continue;
			}

		// ----------------------

		//pos37440:
			if (skipFlag <= 37) {
				skipFlag = maxSkip;	
				Code37066(mem58);
				A = A & 32;
				if (A == 0) {
					//goto pos37184;
					skipFlag = 25;
					continue;
				}
				mem58 = X;
				//goto pos37440;
				skipFlag = 37;
				continue;
			}
		//pos37455:
			if (skipFlag <= 38) {
				skipFlag = maxSkip;	
				Y = mem64;
				mem61 = mem60;

				//if (debug)
				//	PrintRule(mem62);
			}
		//pos37461:
			if (skipFlag <= 39) {
				skipFlag = maxSkip;	
				//37461: LDA (62),y
				A = GetRuleByte(mem62, Y);
				mem57 = A;
				A = A & 127;
				if (A != '='.charCodeAt(0)) {
					mem56++;
					mem56 = mem56 % 256;
					X = mem56;
					input[X] = A;
				}

				//37478: BIT 57
				//37480: BPL 37485  //not negative flag
				if ((mem57 & 128) == 0) {
					//goto pos37485; //???
					skipFlag = 40;
					continue;
				}
				
				//goto pos36554;
				skipFlag = 3;
				continue;
			}
		//pos37485:
			if (skipFlag <= 40) {
				skipFlag = maxSkip;	
				Y++;
				Y = Y % 256;
				//goto pos37461;
				skipFlag = 39;
				continue;
			}
			break;
		}
		return -4;
	}
}