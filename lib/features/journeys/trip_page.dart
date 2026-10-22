import 'package:flutter/material.dart';
import 'package:veribus/features/journeys/journey_page.dart';

/// The journey followed step by step (written in flow 5).
class TripPage extends StatelessWidget {
  const TripPage({required this.args, super.key});

  static const route = '/journeys/trip';

  final JourneyArgs? args;

  @override
  Widget build(BuildContext context) => const Scaffold();
}
