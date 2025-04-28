import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen>
    with SingleTickerProviderStateMixin {
  String suhu = "0";
  String kelembapan = "0";
  bool ledStatus = false;
  bool isConnected = false;
  String connectionStatus = "Menghubungkan ke Firebase...";
  late AnimationController _controller;
  late Animation<double> _animation;
  DatabaseReference? _databaseRef;
  DatabaseReference? _controlRef;

  @override
  void initState() {
    super.initState();
    // Animasi untuk efek pulse pada LED
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    // Inisialisasi Firebase dengan penanganan error
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      debugPrint('Memulai inisialisasi Firebase...');

      // Referensi ke node esiot-db
      _databaseRef = FirebaseDatabase.instance.ref().child('esiot-db');
      _controlRef = FirebaseDatabase.instance.ref().child('Control');

      debugPrint('Referensi database dibuat: esiot-db dan Control');

      // Verifikasi koneksi database
      final connected = FirebaseDatabase.instance.ref(".info/connected");
      connected.onValue.listen((event) {
        final isConnected = event.snapshot.value as bool? ?? false;
        debugPrint('Status koneksi Firebase: $isConnected');
        setState(() {
          this.isConnected = isConnected;
          connectionStatus = isConnected
              ? "Terhubung ke Firebase"
              : "Tidak terhubung ke Firebase. Pastikan koneksi internet aktif.";
        });
      });

      // Mencoba untuk membaca dari esiot-db
      _databaseRef?.onValue.listen((event) {
        debugPrint('Data diterima dari esiot-db: ${event.snapshot.value}');
        if (event.snapshot.value != null) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            debugPrint('Data yang diproses: $data');

            if (mounted) {
              setState(() {
                suhu = data['suhu']?.toString() ?? "0";
                kelembapan = data['kelembapan']?.toString() ?? "0";
                ledStatus = data['led']?.toString() == "1";

                debugPrint(
                    'Data diperbarui - Suhu: $suhu, Kelembapan: $kelembapan, LED: $ledStatus');

                if (ledStatus) {
                  _controller.repeat(reverse: true);
                } else {
                  _controller.stop();
                  _controller.value = 0.0;
                }
              });
            }
          } catch (e) {
            debugPrint('Error saat memproses data: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
          }
        } else {
          debugPrint('Tidak ada data di node esiot-db');
        }
      }).onError((error) {
        debugPrint('Error saat membaca data dari esiot-db: $error');
        debugPrint('Stack trace: ${StackTrace.current}');
        _tryReadFromSensorNode();
      });

      // Cek status LED dari node Control
      _controlRef?.onValue.listen((event) {
        debugPrint('Data diterima dari Control: ${event.snapshot.value}');
        if (event.snapshot.value != null) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            if (data['led'] != null && mounted) {
              setState(() {
                ledStatus = data['led'].toString() == "1";
                debugPrint('Status LED diperbarui dari Control: $ledStatus');

                if (ledStatus) {
                  _controller.repeat(reverse: true);
                } else {
                  _controller.stop();
                  _controller.value = 0.0;
                }
              });
            }
          } catch (e) {
            debugPrint('Error saat memproses data Control: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
          }
        }
      });
    } catch (e) {
      debugPrint('Error saat inisialisasi Firebase references: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          connectionStatus = "Gagal terhubung ke Firebase: ${e.toString()}";
        });
      }
    }
  }

  void _tryReadFromSensorNode() {
    try {
      DatabaseReference? sensorRef =
          FirebaseDatabase.instance.ref().child('Sensor');
      sensorRef.onValue.listen((event) {
        if (event.snapshot.value != null && mounted) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            setState(() {
              // Mengambil nilai suhu dan kelembapan dari node Sensor
              suhu = data['suhu']?.toString() ?? "0";
              kelembapan = data['kelembapan']?.toString() ?? "0";
            });
          } catch (e) {
            debugPrint('Error saat memproses data Sensor: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error saat membaca dari node Sensor: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fungsi untuk menyalakan LED
  void _turnOnLed() {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak dapat mengirim data: Firebase tidak terhubung')),
      );
      return;
    }
    setState(() {
      ledStatus = true;
      // Update di node esiot-db
      _databaseRef?.update({'led': 1}).then((_) {
        debugPrint('LED berhasil dinyalakan di esiot-db');
      }).catchError((error) {
        debugPrint('Error saat menyalakan LED di esiot-db: $error');
      });
      // Update juga di node Control untuk kompatibilitas
      _controlRef?.update({'led': 1}).then((_) {
        debugPrint('LED berhasil dinyalakan di Control');
      }).catchError((error) {
        debugPrint('Error saat menyalakan LED di Control: $error');
      });
    });
  }

  // Fungsi untuk mematikan LED
  void _turnOffLed() {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak dapat mengirim data: Firebase tidak terhubung')),
      );
      return;
    }
    setState(() {
      ledStatus = false;
      // Update di node esiot-db
      _databaseRef?.update({'led': 0}).then((_) {
        debugPrint('LED berhasil dimatikan di esiot-db');
      }).catchError((error) {
        debugPrint('Error saat mematikan LED di esiot-db: $error');
      });
      // Update juga di node Control untuk kompatibilitas
      _controlRef?.update({'led': 0}).then((_) {
        debugPrint('LED berhasil dimatikan di Control');
      }).catchError((error) {
        debugPrint('Error saat mematikan LED di Control: $error');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text(
          'Monitoring IoT',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Status koneksi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isConnected ? Colors.green[100]! : Colors.red[100]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isConnected ? Colors.green[100] : Colors.red[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          color: isConnected ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          connectionStatus,
                          style: TextStyle(
                            color: isConnected
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.thermostat,
                        title: 'Suhu',
                        value: '$suhu°C',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.water_drop,
                        title: 'Kelembapan',
                        value: '$kelembapan%',
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                      const Text(
                        'Kontrol LED',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ledStatus
                                  ? Colors.amber[100]
                                  : Colors.grey[100],
                              boxShadow: ledStatus
                                  ? [
                                      BoxShadow(
                                        color: Colors.amber.withAlpha(
                                          (77 + (_animation.value * 102))
                                              .toInt(),
                                        ),
                                        blurRadius:
                                            20 + (_animation.value * 15),
                                        spreadRadius:
                                            5 + (_animation.value * 5),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lightbulb,
                                color: ledStatus ? Colors.amber : Colors.grey,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(
                            onPressed: _turnOnLed,
                            label: 'HIDUP',
                            isActive: ledStatus,
                          ),
                          const SizedBox(width: 16),
                          _buildControlButton(
                            onPressed: _turnOffLed,
                            label: 'MATI',
                            isActive: !ledStatus,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required String label,
    required bool isActive,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.amber : Colors.grey[100],
        foregroundColor: isActive ? Colors.white : Colors.black54,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
