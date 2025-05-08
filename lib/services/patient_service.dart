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
    int? status,
    String? message,
    int? totalHelp,
  }) async {
    // Get existing patient data
    final existingPatient = await getPatientById(patientId);

    // Prepare update data
    final Map<String, dynamic> updateData = {
      'name': name,
      'last_login': DateTime.now().toIso8601String(),
    };

    // Only update status and message if they are explicitly provided
    // Otherwise, keep the existing values
    if (status != null) {
      updateData['status'] = status;
    } else if (existingPatient == null) {
      // Only set default status for new patients
      updateData['status'] = 0;
    }

    if (message != null) {
      updateData['message'] = message;
    } else if (existingPatient == null) {
      // Only set default message for new patients
      updateData['message'] = '';
    }

    if (totalHelp != null) {
      updateData['total_help'] = totalHelp;
    } else if (existingPatient == null) {
      // Only set default totalHelp for new patients
      updateData['total_help'] = 0;
    }

    await _databaseRef.child('patients').child(patientId).update(updateData);
  }

  // Memperbarui status bantuan pasien
  Future<void> updateHelpStatus(String patientId, bool isRequesting) async {
    final patient = await getPatientById(patientId);
    if (patient != null) {
      final int totalHelp = (patient['total_help'] ?? 0) as int;
      await _databaseRef.child('patients').child(patientId).update({
        'status': isRequesting
            ? 0
            : 1, // When isRequesting is true, set status to 0 (complete)
        'message': isRequesting ? '' : '${patient['name']}\nMeminta Bantuan',
        'total_help': totalHelp,
      });
    }
  }

  // Meminta bantuan
  Future<void> requestHelp(
      String patientId, String name, int currentTotalHelp) async {
    // Check if there's already a pending request
    final patient = await getPatientById(patientId);
    if (patient != null && patient['status'] == 1) {
      throw Exception(
          'Anda masih memiliki permintaan bantuan yang belum ditangani');
    }

    await _databaseRef.child('patients').child(patientId).update({
      'status': 1,
      'message': '$name\nMeminta Bantuan',
      'total_help': currentTotalHelp + 1,
      'last_login': DateTime.now().toIso8601String(),
    });
  }
}
