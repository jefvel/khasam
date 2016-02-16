package;

import com.jefvel.sam.Sam;
import haxe.Timer;
import kha.Sound;

class Unknown {
	var sam:Sam;
	function s(str:String, speed:Int, pitch:Int, delay:Int) {
		Timer.delay(function() {
			sam.say(str, pitch, speed, true);
		}, delay);
	}
	
	public function new() {
		sam = new Sam();
		
		sam.enableSingMode(true);
		
		s("ohohoh ", 40, 64, 0);
		s("ohohoh ", 40, 76, 200);
		s("sehehehehehehehehehey ", 40, 96, 400);
		s("kaeaeaeaeaeaeaeaeaen ", 40, 76, 1000);
		s("yuxuxuxuxuxuxw ", 40, 64, 1500);
		s("siyiyiyiyiyiyiyiyiyiyiyiyiyiyiyiyiyiy ", 40, 48, 1900);
		s("baaaaay ", 40, 38, 2900);
		s("dhaaaxaxaxax ", 40, 42, 3200);
		s("daoaoaoaoaoaoaonz ", 40, 48, 3400);
		s("ererererererer ", 40, 76, 4000);
		s("liyiyiyiyiyiyiyiyiy ", 40, 68, 4400);
		s("laaaaaaaaaaaaaaaaaaaaaaaaayt ", 40, 64, 4900);
		s("whahahaht ", 40, 64, 6000);
		s("sohohuw ", 40, 64, 6200);
		s("praaaaaaaaaaaaaaaauwd ", 40, 38, 6400);
		s("liyiyiy ", 40, 42, 7200);
		s("wiyiyiyiyiyiyiyiyiy ", 40, 48, 7500);
		s("/heheheheheheheheheheheheheheheheheheyld ", 40, 51, 8000);
		s("aeaeaeaet ", 40, 56, 9100);
		s("dhaaaxaxaxax ", 40, 51, 9400);
		s("twaaaaaaaaaaaaaaiy ", 40, 48, 9600);
		
		Timer.delay(function() {
			sam.enableSingMode(false);
			sam.say("that is all, and now I am tired.", 50, 80);
		}, 12000);
	}
}
