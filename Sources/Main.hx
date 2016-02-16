package;

import kha.System;

class Main {
	public static function main() {
		System.init("Sam Demo", 1024, 768, function () {
			new Unknown();
		});
	}
}
