var solution = new Solution('SAM');
var project = new Project('SAM');
project.setDebugDir('build/windows');
project.addSubProject(Solution.createProject('build/windows-build'));
project.addSubProject(Solution.createProject('F:/Development/HaxeToolkit/haxe/lib/kha/16,1,2'));
project.addSubProject(Solution.createProject('F:/Development/HaxeToolkit/haxe/lib/kha/16,1,2/Kore'));
solution.addProject(project);
return solution;
