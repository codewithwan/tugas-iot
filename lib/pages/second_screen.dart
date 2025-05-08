import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
// import '../services/patient_service.dart';
import 'patient_dashboard.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // final PatientService _patientService = PatientService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      await Firebase.initializeApp();
      final connected = FirebaseDatabase.instance.ref(".info/connected");
      connected.onValue.listen((event) {
        final isConnected = event.snapshot.value as bool? ?? false;
        setState(() {
          _isConnected = isConnected;
          if (!isConnected) {
            _errorMessage =
                'Tidak terhubung ke internet. Mohon periksa koneksi Anda.';
          }
        });
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Gagal terhubung ke server. Mohon coba lagi nanti.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage =
            'Tidak terhubung ke internet. Mohon periksa koneksi Anda.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      final String patientName = _nameController.text.trim().toLowerCase();

      // Validate if the name is either "pasien1" or "pasien2"
      if (patientName != "pasien1" && patientName != "pasien2") {
        setState(() {
          _errorMessage = 'Pasien tidak terdaftar';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final String patientId = patientName;

        // Get existing patient data if any
        // final existingPatient = await _patientService.getPatientById(patientId);

        // // Create or update patient
        // await _patientService.createOrUpdatePatient(
        //   patientId: patientId,
        //   name: patientName,
        // );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDashboard(
                patientId: patientId,
                username: patientName,
                name: patientName,
              ),
            ),
          );
        }
      } on TimeoutException {
        setState(() {
          _errorMessage = 'Koneksi timeout. Mohon coba lagi.';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan. Mohon coba lagi nanti.';
          _isLoading = false;
        });
        debugPrint('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 64,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Masuk Sebagai Pasien',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masukkan nama pasien',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isConnected,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nama Pasien',
                            labelStyle: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                            hintText: 'Masukkan pasien1 atau pasien2',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[200]!,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            final name = value.trim().toLowerCase();
                            if (name != "pasien1" && name != "pasien2") {
                              return 'Hanya "pasien1" dan "pasien2" yang diperbolehkan';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red[100]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _isConnected && !_isLoading ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black87),
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
