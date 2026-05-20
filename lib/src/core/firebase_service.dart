import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService instance = FirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference ref(String path) => _db.ref(path);

  Future<void> set(String path, Object? value) => ref(path).set(value);

  Future<void> push(String path, Object? value) async {
    final node = ref(path).push();
    await node.set(value);
  }

  Stream<DatabaseEvent> onValue(String path) => ref(path).onValue;

  Future<DataSnapshot> getOnce(String path) => ref(path).get();
}
