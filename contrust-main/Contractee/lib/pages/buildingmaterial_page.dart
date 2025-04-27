import 'package:backend/models/appbar.dart';
import 'package:flutter/material.dart';

class Buildingmaterial extends StatelessWidget {
  const Buildingmaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Materials"),
      drawer: const MenuDrawer(),
      body: const Center(
        child: Text(
          '',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}