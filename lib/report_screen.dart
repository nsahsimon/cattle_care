import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  final List<Map<String, String>> reportData;

  ReportScreen({required this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Table(
            border: TableBorder.all(color: Colors.black),
            defaultColumnWidth: FixedColumnWidth(150),
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Center(child: Text('Tag number', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  TableCell(
                    child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
              ...reportData.map((data) {
                return TableRow(
                  children: [
                    TableCell(
                      child: Center(child: Text(data['tag_number'] ?? '')),
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