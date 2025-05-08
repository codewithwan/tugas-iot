import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ThirdScreen extends StatefulWidget {
  const ThirdScreen({super.key});

  @override
  State<ThirdScreen> createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  final PatientService _patientService = PatientService();
  Map<String, dynamic> _patients = {};

  @override
  void initState() {
    super.initState();
    _setupDatabaseListener();
  }

  void _setupDatabaseListener() {
    _patientService.getPatients().listen((patients) {
      setState(() {
        _patients = patients;
      });
    });
  }

  Future<void> _handleRequest(String patientId, bool isRequesting) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Konfirmasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              'Apakah Anda yakin ingin menandai permintaan bantuan ini sebagai selesai?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Ya, Tandai Selesai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        );
      },
    );

    if (confirm == true) {
      await _patientService.updateHelpStatus(patientId, isRequesting);
    }
  }

  Widget _buildChart() {
    if (_patients.isEmpty) return const SizedBox.shrink();

    final List<BarChartGroupData> barGroups = [];
    final List<String> patientNames = [];
    int index = 0;

    _patients.forEach((id, data) {
      final totalHelp = (data['total_help'] ?? 0) as int;
      patientNames.add(data['name'] ?? 'Pasien $id');

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: totalHelp.toDouble(),
              color: Colors.amber,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Bantuan Pasien',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    // tooltipBackgroundColor: Colors.amber.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${patientNames[groupIndex]}\n${rod.toY.toInt()} bantuan',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < patientNames.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              patientNames[value.toInt()].split(' ')[0],
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Monitor Pasien',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_alt_outlined,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Daftar Pasien',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildChart(),
                      const SizedBox(height: 20),
                      _patients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_off_outlined,
                                      color: Colors.amber,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada pasien terdaftar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: _patients.entries.map((entry) {
                                final patientId = entry.key;
                                final patientData = entry.value;
                                final isRequesting = patientData['status'] == 1;
                                final message = patientData['message'] ?? '';
                                final name =
                                    patientData['name'] ?? 'Pasien $patientId';
                                final totalHelp =
                                    (patientData['total_help'] ?? 0) as int;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isRequesting
                                                    ? Colors.amber
                                                    : Colors.amber
                                                        .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: isRequesting
                                                    ? Colors.white
                                                    : Colors.amber,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'ID: $patientId',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Total bantuan: $totalHelp',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (patientData[
                                                              'last_login'] !=
                                                          null) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          'Permintaan bantuan: ${_formatLastLogin(patientData['last_login'])}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isRequesting
                                                    ? Colors.red[50]
                                                    : Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isRequesting
                                                    ? 'Meminta Bantuan'
                                                    : 'Aman',
                                                style: TextStyle(
                                                  color: isRequesting
                                                      ? Colors.red[700]
                                                      : Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (message.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Text(
                                              message,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (isRequesting)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _handleRequest(
                                                          patientId, true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.amber,
                                                    foregroundColor:
                                                        Colors.black87,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Tandai Selesai',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastLogin(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
