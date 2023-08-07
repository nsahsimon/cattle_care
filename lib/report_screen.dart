import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  final List<Map<String, String>> reportData;

  ReportScreen({required this.reportData});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
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
        actions: [
          TextButton(
              onPressed: () {
                //clear report
                widget.reportData.clear();
                setState((){});
              },
              child: Text("clear", style: TextStyle(color: Colors.white)))
        ],
      ),
      body:widget.reportData.isEmpty ? Center(child: Text("No data available")) : SingleChildScrollView(
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
              ...widget.reportData.map((data) {
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