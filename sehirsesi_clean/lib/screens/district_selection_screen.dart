import 'package:flutter/material.dart';
import '../services/district_service.dart';

class DistrictSelectionScreen extends StatefulWidget {
  final String city;

  const DistrictSelectionScreen({super.key, required this.city});

  @override
  State<DistrictSelectionScreen> createState() =>
      _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen> {
  List<String> districts = [];

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  void loadDistricts() async {
    final result = await DistrictService.getDistricts(widget.city);

    setState(() {
      districts = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.city} İlçeleri"),
      ),
      body: ListView.builder(
        itemCount: districts.length,
        itemBuilder: (context, index) {
          final district = districts[index];

          return ListTile(
            title: Text(district),
            onTap: () {
              Navigator.pop(context, district);
            },
          );
        },
      ),
    );
  }
}