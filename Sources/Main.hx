package;

import kha.System;

class Main {
	public static function main() {
		System.init("Unknown", 1024, 768, function () {
			new Unknown();
		});
	}
}
