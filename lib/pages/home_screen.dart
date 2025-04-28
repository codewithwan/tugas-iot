import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'first_screen.dart';
import 'second_screen.dart';
import 'third_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String suhu = "0";
  String kelembapan = "0";
  bool ledStatus = false;
  bool isConnected = false;
  String connectionStatus = "Menghubungkan ke Firebase...";
  late AnimationController _controller;
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
    // Inisialisasi Firebase dengan penanganan error
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      _databaseRef = FirebaseDatabase.instance.ref().child('esiot-db');
      _controlRef = FirebaseDatabase.instance.ref().child('Control');

      final connected = FirebaseDatabase.instance.ref(".info/connected");
      connected.onValue.listen((event) {
        final isConnected = event.snapshot.value as bool? ?? false;
        setState(() {
          this.isConnected = isConnected;
          connectionStatus = isConnected
              ? "Terhubung ke Firebase"
              : "Tidak terhubung ke Firebase. Pastikan koneksi internet aktif.";
        });
      });

      _databaseRef?.onValue.listen((event) {
        if (event.snapshot.value != null) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            if (mounted) {
              setState(() {
                suhu = data['suhu']?.toString() ?? "0";
                kelembapan = data['kelembapan']?.toString() ?? "0";
                ledStatus = data['led']?.toString() == "1";
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
          }
        }
      }).onError((error) {
        debugPrint('Error saat membaca data dari esiot-db: $error');
        _tryReadFromSensorNode();
      });

      _controlRef?.onValue.listen((event) {
        if (event.snapshot.value != null) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            if (data['led'] != null && mounted) {
              setState(() {
                ledStatus = data['led'].toString() == "1";
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
          }
        }
      });
    } catch (e) {
      debugPrint('Error saat inisialisasi Firebase references: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('IoT Dashboard'),
        backgroundColor: Colors.amberAccent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pilih Menu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber[100]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Mahasiswa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nama: Muhammad Ridan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'NIM: 3.34.23.3.15',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Kelas: IK-2D',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        context,
                        'Monitoring',
                        'Monitor suhu dan kelembapan',
                        Icons.monitor_heart,
                        Colors.amber,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FirstScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        'Login Pasien',
                        'Login untuk pasien',
                        Icons.person,
                        Colors.amber,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SecondScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        'Monitor Pasien',
                        'Monitor permintaan bantuan',
                        Icons.medical_services,
                        Colors.amber,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThirdScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        'Pengaturan',
                        'Pengaturan aplikasi',
                        Icons.settings,
                        Colors.amber,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur ini akan segera hadir!'),
                            ),
                          );
                        },
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
