import 'package:firebase_database/firebase_database.dart';

class PatientService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Mendapatkan semua data pasien
  Stream<Map<String, dynamic>> getPatients() {
    return _databaseRef.child('patients').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  // Mendapatkan data pasien berdasarkan ID
  Future<Map<String, dynamic>?> getPatientById(String patientId) async {
    final snapshot =
        await _databaseRef.child('patients').child(patientId).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Membuat atau memperbarui data pasien
  Future<void> createOrUpdatePatient({
    required String patientId,
    required String name,
    int status = 0,
    String message = '',
    int totalHelp = 0,
  }) async {
    await _databaseRef.child('patients').child(patientId).update({
      'name': name,
      'status': status,
      'message': message,
      'total_help': totalHelp,
      'last_login': DateTime.now().toIso8601String(),
    });
  }

  // Memperbarui status bantuan pasien
  Future<void> updateHelpStatus(String patientId, bool isRequesting) async {
    final patient = await getPatientById(patientId);
    if (patient != null) {
      final int totalHelp = (patient['total_help'] ?? 0) as int;
      await _databaseRef.child('patients').child(patientId).update({
        'status': isRequesting ? 0 : 1,
        'message': isRequesting ? '' : '${patient['name']}\nMeminta Bantuan',
        'total_help': isRequesting ? totalHelp : totalHelp,
      });
    }
  }

  // Meminta bantuan
  Future<void> requestHelp(
      String patientId, String name, int currentTotalHelp) async {
    await _databaseRef.child('patients').child(patientId).update({
      'status': 1,
      'message': '$name\nMeminta Bantuan',
      'total_help': currentTotalHelp + 1,
    });
  }
}
