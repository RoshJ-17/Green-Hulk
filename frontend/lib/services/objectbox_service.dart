import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../objectbox.g.dart'; // Created by `flutter pub run build_runner build`

class ObjectBoxService {
  static late final Store store;

  static Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, "objectbox");
    store = await openStore(directory: storeDir);
  }
}
