import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';

class AttendanceResultPage extends StatelessWidget {
  final String subjectId;
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  const AttendanceResultPage({super.key, required this.subjectId, required this.studentId, required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    final formattedRange =
        '${DateFormat('dd/MM/yyyy').format(startDate)} - '
        '${DateFormat('dd/MM/yyyy').format(endDate)}';

    return Scaffold(
      // appBar: AppBar(title: const Text('Attendance Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<AttendanceRecordModel>>(
          future: locator.attendanceRecordRepository.getRecordsByDateRange(subjectId, studentId, startDate, endDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return _buildNoData(formattedRange);
            }

            return _buildAttendanceList(records);
          },
        ),
      ),
    );
  }

  // ---------------- UI Widgets ----------------

  Widget _buildAttendanceList(List<AttendanceRecordModel> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final date = DateFormat('dd/MM/yyyy').format(record.scanTime);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(title: Text(date), trailing: _buildStatusChip(record.status as String)),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'present':
        color = Colors.green;
        label = 'มาเรียน';
        break;
      case 'late':
        color = Colors.orange;
        label = 'มาสาย';
        break;
      case 'absent':
      default:
        color = Colors.red;
        label = 'ขาดเรียน';
    }

    return Chip(label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)), backgroundColor: color);
  }

  Widget _buildNoData(String formattedRange) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('ไม่พบข้อมูลการมาเรียน\nช่วงวันที่ $formattedRange', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
