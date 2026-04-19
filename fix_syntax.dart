import 'dart:io';

void main() {
  final files = [
    'e:/HackArch/aphora/lib/ui/learning/learning_session_page.dart',
    'e:/HackArch/aphora/lib/ui/learning/task_list_page.dart',
    'e:/HackArch/aphora/lib/ui/profile/profile_page.dart',
    'e:/HackArch/aphora/lib/ui/therapist/patient_bookings_page.dart',
  ];
  
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Fix pattern: appBar: ClinicalAppBar(title: "Page"),\s*backgroundColor:.*?\s*\),
    content = content.replaceAll(RegExp(r'appBar: ClinicalAppBar\(title: "Page"\),\s*backgroundColor:[^,]+,\s*elevation:[^,]+,\s*leading:[^,]+,\s*onPressed:[^,]+,\s*\),\s*\),'), 'appBar: const ClinicalAppBar(title: "Page", showBackButton: true),');
    content = content.replaceAll(RegExp(r'appBar: ClinicalAppBar\(title: "Page"\),\s*backgroundColor:[^,]+,\s*elevation:[^,]+,\s*\),'), 'appBar: const ClinicalAppBar(title: "Page", showBackButton: true),');
    content = content.replaceAll(RegExp(r'appBar: ClinicalAppBar\(title: "Page"\),\s*backgroundColor:[^,]+,\s*foregroundColor:[^,]+,\s*\),'), 'appBar: const ClinicalAppBar(title: "Page", showBackButton: true),');
    content = content.replaceAll(RegExp(r'appBar: ClinicalAppBar\(title: "Page"\),\s*backgroundColor:[^,]+,\s*\),'), 'appBar: const ClinicalAppBar(title: "Page", showBackButton: true),');

    // Remove any orphaned ), before ody:
    content = content.replaceAll(RegExp(r'\),\s*body:'), 'body:');

    file.writeAsStringSync(content);
    print('Fixed \');
  }
}
