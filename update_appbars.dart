import 'dart:io';

void main() {
  final dir = Directory('e:/HackArch/aphora/lib/ui');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    if (file.path.contains('clinical_app_bar.dart')) continue;
    if (file.path.contains('assessment_page.dart')) continue;
    if (file.path.contains('word_naming_list_page.dart')) continue;
    if (file.path.contains('word_naming_page.dart')) continue;
    if (file.path.contains('home_page.dart')) continue;
    if (file.path.contains('main_navigation.dart')) continue;
    
    var content = file.readAsStringSync();
    
    bool changed = false;
    
    // Pattern matches appBar: AppBar(...) with DuoColors etc.
    final complexPattern = RegExp(r'appBar:\s*AppBar\(\s*(automaticallyImplyLeading:[^,]*,?)?\s*(?:title:\s*Center\(\s*child:\s*)?title:\s*(?:const\s*)?Text\(([^,]+)(?:,[^)]*)?\),?\s*(?:elevation:[^,]*,?)?\s*(?:backgroundColor:[^,]*,?)?\s*\),?');
    if (complexPattern.hasMatch(content)) {
        content = content.replaceAllMapped(complexPattern, (match) {
            final titleStr = match.group(2);
            return 'appBar: ClinicalAppBar(title: \),';
        });
        changed = true;
    }
    
    final simplePattern = RegExp(r'appBar:\s*AppBar\(\s*title:\s*(?:const\s*)?Text\(([^)]+)\),?\s*\),?');
    if (simplePattern.hasMatch(content)) {
        content = content.replaceAllMapped(simplePattern, (match) {
            final titleStr = match.group(1);
            return 'appBar: ClinicalAppBar(title: \),';
        });
        changed = true;
    }
    
    if (changed && !content.contains('clinical_app_bar.dart')) {
        content = "import 'package:aphora/ui/widgets/clinical_app_bar.dart';\n" + content;
    }
    
    if (changed) {
        file.writeAsStringSync(content);
        print('Updated: ' + file.path);
    }
  }
}
