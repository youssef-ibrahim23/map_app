import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_app/features/map/services/map_services.dart';
import 'features/map/view/map_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashView extends StatefulWidget{
  const SplashView({super.key});

  @override
  State<StatefulWidget> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>{

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      await MapServices().checkAndRequestLocationPermission();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MapView()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/logo.png') , width: 300,).animate().scale(duration: 1.seconds).then().shimmer(duration: 500.ms, color: Colors.white,),
            SizedBox(height: 40,),
            Text('Map App', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),).animate().move(begin: const Offset(0, 350), duration: 1.seconds).then().shimmer(
              duration: 500.ms,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}