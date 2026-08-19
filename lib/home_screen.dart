import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tracking_screen.dart';
import 'channel/live_activity_channel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _drivers = [
    {
      'name': 'Rahul K.',
      'car': 'Swift Dzire',
      'plate': 'GJ 01 AB 1234',
      'distance': 3.2,
      'eta': 8,
      'asset': 'assets/images/driver1.jpeg',
      'fileName': 'driver1.jpeg',
    },
    {
      'name': 'Priya M.',
      'car': 'Honda City',
      'plate': 'GJ 05 CD 5678',
      'distance': 1.8,
      'eta': 5,
      'asset': 'assets/images/driver2.jpeg',
      'fileName': 'driver2.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Dynamic Island\nDemo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a ride to see Dynamic Island in action',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 40),
              const Text(
                'AVAILABLE RIDES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ..._drivers.map((d) => _DriverCard(driver: d)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverCard({required this.driver});

  Future<void> _startRide(BuildContext context) async {
    // Save image to App Group first
    final imagePath = await LiveActivityChannel.saveImageToAppGroup(
      assetPath: driver['asset'] as String,
      fileName: driver['fileName'] as String,
    );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(
          driverName: driver['name'] as String,
          carModel: driver['car'] as String,
          plateNumber: driver['plate'] as String,
          driverImagePath: imagePath ?? '',
          initialDistanceKm: driver['distance'] as double,
          initialEtaMinutes: driver['eta'] as int,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _startRide(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C47FF).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            // Driver avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF6C47FF).withOpacity(0.15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  driver['asset'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF6C47FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${driver['car']} · ${driver['plate']}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(driver['distance'] as double).toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${driver['eta']} min',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}