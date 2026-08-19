import 'package:flutter/material.dart';
import 'dart:async';
import 'channel/live_activity_channel.dart';

enum RideStage { preparing, pickedUp, arriving, delivered }

class TrackingScreen extends StatefulWidget {
  final String driverName;
  final String carModel;
  final String plateNumber;
  final String driverImagePath;
  final double initialDistanceKm;
  final int initialEtaMinutes;

  const TrackingScreen({
    super.key,
    required this.driverName,
    required this.carModel,
    required this.plateNumber,
    required this.driverImagePath,
    required this.initialDistanceKm,
    required this.initialEtaMinutes,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String? _activityId;
  late double _distanceKm;
  late int _etaMinutes;
  RideStage _stage = RideStage.preparing;
  Timer? _timer;
  bool _started = false;

  String get _stageLabel {
    switch (_stage) {
      case RideStage.preparing:
        return 'Preparing your order';
      case RideStage.pickedUp:
        return 'Driver picked up';
      case RideStage.arriving:
        return 'Almost there';
      case RideStage.delivered:
        return 'Delivered!';
    }
  }

  String get _stageKey {
    switch (_stage) {
      case RideStage.preparing:
        return 'preparing';
      case RideStage.pickedUp:
        return 'pickedup';
      case RideStage.arriving:
        return 'arriving';
      case RideStage.delivered:
        return 'delivered';
    }
  }

  Color get _stageColor {
    switch (_stage) {
      case RideStage.preparing:
        return const Color(0xFF6C47FF);
      case RideStage.pickedUp:
        return const Color(0xFF0A84FF);
      case RideStage.arriving:
        return const Color(0xFFFF9F0A);
      case RideStage.delivered:
        return const Color(0xFF30D158);
    }
  }

  @override
  void initState() {
    super.initState();
    _distanceKm = widget.initialDistanceKm;
    _etaMinutes = widget.initialEtaMinutes;
    _launchActivity();
  }

  Future<void> _launchActivity() async {
    final id = await LiveActivityChannel.startRide(
      driverName: widget.driverName,
      carModel: widget.carModel,
      plateNumber: widget.plateNumber,
      driverImagePath: widget.driverImagePath,
      distanceKm: _distanceKm,
      etaMinutes: _etaMinutes,
      stage: _stageKey,
    );
    if (!mounted) return;

    if (id == null) {
      setState(() {
        _activityId = null;
        _started = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start Live Activity for this ride.'),
        ),
      );
      return;
    }

    setState(() {
      _activityId = id;
      _started = true;
    });
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_stage == RideStage.delivered) return;

      setState(() {
        _distanceKm = (_distanceKm - 0.25).clamp(0.0, 99.0);
        _etaMinutes = (_etaMinutes - 1).clamp(0, 99);

        if (_distanceKm > 2.0) {
          _stage = RideStage.preparing;
        } else if (_distanceKm > 1.0) {
          _stage = RideStage.pickedUp;
        } else if (_distanceKm > 0.1) {
          _stage = RideStage.arriving;
        } else {
          _stage = RideStage.delivered;
        }
      });

      if (_stage == RideStage.delivered) {
        _timer?.cancel();
        final id = _activityId;
        if (id == null) return;
        await LiveActivityChannel.endRide(
          activityId: id,
          finalMessage: 'Delivered! Enjoy your meal.',
        );
        return;
      }

      final id = _activityId;
      if (id != null) {
        await LiveActivityChannel.updateRide(
          activityId: id,
          distanceKm: _distanceKm,
          etaMinutes: _etaMinutes,
          stage: _stageKey,
          status: _stageLabel,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final id = _activityId;
    if (id != null && _stage != RideStage.delivered) {
      LiveActivityChannel.endRide(
        activityId: id,
        finalMessage: 'Ride cancelled',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Live Tracking'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Stage indicator
              _StageIndicator(currentStage: _stage),
              const SizedBox(height: 32),

              // Main status card
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _stageColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Driver avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _stageColor, width: 2.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/driver1.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => CircleAvatar(
                            backgroundColor: _stageColor.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person_rounded,
                              color: _stageColor,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.carModel} · ${widget.plateNumber}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_stage != RideStage.delivered) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(
                            value: _distanceKm.toStringAsFixed(1),
                            unit: 'km',
                            label: 'Distance',
                            color: _stageColor,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white12,
                          ),
                          _Stat(
                            value: '$_etaMinutes',
                            unit: 'min',
                            label: 'ETA',
                            color: _stageColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _stageLabel,
                        key: ValueKey(_stage),
                        style: TextStyle(
                          color: _stageColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Dynamic Island hint
              if (_started && _stage != RideStage.delivered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lock your phone — watch Dynamic Island update live',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final RideStage currentStage;
  const _StageIndicator({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = [
      RideStage.preparing,
      RideStage.pickedUp,
      RideStage.arriving,
      RideStage.delivered,
    ];
    final labels = ['Preparing', 'Picked up', 'Arriving', 'Delivered'];
    final current = stages.indexOf(currentStage);

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = current > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? const Color(0xFF6C47FF) : Colors.white12,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = current >= idx;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF6C47FF) : Colors.white12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[idx],
              style: TextStyle(
                color: done ? Colors.white54 : Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
