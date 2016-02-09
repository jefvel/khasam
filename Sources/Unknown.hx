package;

import com.jefvel.sam.Sam;
import kha.Framebuffer;
import kha.Scheduler;
import kha.Sound;
import kha.System;

class Unknown {
	var sam:Sam;
	var s:Sound;
	public function new() {
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		sam = new Sam();
		var b = sam.getBuffer();
		b.play();
	}

	function update(): Void {
		
	}

	function render(framebuffer: Framebuffer): Void {		
	}
}
