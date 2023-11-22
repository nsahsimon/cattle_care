import 'package:flutter/material.dart';
import 'package:cattle_care/data.dart';

class AttendanceReportScreen extends StatefulWidget {

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
              onPressed: () {
                //clear report
                myAttendanceReportData.clear();
                setState((){});
              },
              child: Text("clear", style: TextStyle(color: Colors.white)))
        ],
      ),
      body:myAttendanceReportData.isEmpty ? Center(child: Text("No data available")) : SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Table(
            border: TableBorder.all(color: Colors.black),
            defaultColumnWidth: FixedColumnWidth(150),
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Center(child: Text('Cattle-ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  TableCell(
                    child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
              ...myAttendanceReportData.map((data) {
                return TableRow(
                  children: [
                    TableCell(
                      child: Center(child: Text(data['cattle_id'] ?? '')),
                    ),
                    TableCell(
                      child: Center(child: Text(data['status'] ?? '')),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}