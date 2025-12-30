import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';

class AttendanceResultPage extends StatelessWidget {
  final String subjectId;
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  const AttendanceResultPage({
    super.key,
    required this.subjectId,
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedRange =
        '${DateFormat('dd/MM/yyyy').format(startDate)} - '
        '${DateFormat('dd/MM/yyyy').format(endDate)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<AttendanceRecordModel>>(
          future: locator.attendanceRecordRepository.getRecordsByDateRange(
            subjectId,
            studentId,
            startDate,
            endDate,
          ),
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

            // คำนวณสถิติ
            final presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
            final lateCount = records.where((r) => r.status == AttendanceStatus.late).length;
            final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;

            return Column(
              children: [
                // Summary Card (ไม่ scroll)
                _buildSummaryCard(presentCount, lateCount, absentCount),
                const SizedBox(height: 16),
                // Attendance List (scroll ได้)
                Expanded(
                  child: _buildAttendanceList(records),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int presentCount, int lateCount, int absentCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String>(
            future: _getSubjectName(subjectId),
            builder: (context, snapshot) {
              return Text(
                'Subject: ${snapshot.data ?? subjectId}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 8),
          Text('Date: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
          Text('To date: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Present', presentCount, Colors.green),
              _buildStatColumn('Late', lateCount, Colors.orange),
              _buildStatColumn('Absent', absentCount, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildAttendanceList(List<AttendanceRecordModel> records) {
    return ListView.builder(
      // ✅ ไม่ต้องใช้ shrinkWrap เพราะอยู่ใน Expanded แล้ว
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final date = DateFormat('dd/MM/yyyy').format(record.scanTime);
        final time = DateFormat('HH:mm').format(record.scanTime);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              _getStatusIcon(record.status),
              color: _getStatusColor(record.status),
            ),
            title: Text(date),
            subtitle: Text('Time: $time'),
            trailing: _buildStatusChip(record.status),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    String label;

    switch (status) {
      case AttendanceStatus.present:
        color = Colors.green;
        label = 'Present';
        break;
      case AttendanceStatus.late:
        color = Colors.orange;
        label = 'Late';
        break;
      case AttendanceStatus.absent:
        color = Colors.red;
        label = 'Absent';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  Future<String> _getSubjectName(String subjectId) async {
    try {
      final subject = await locator.subjectRepository.getSubject(subjectId);
      return subject?.name ?? subjectId;
    } catch (e) {
      return subjectId;
    }
  }

  Widget _buildNoData(String formattedRange) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'ไม่พบข้อมูลการมาเรียน\nช่วงวันที่ $formattedRange',
            textAlign: TextAlign.center,
          ),
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}