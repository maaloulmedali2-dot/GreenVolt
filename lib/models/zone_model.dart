// ─────────────────────────────────────────────────────────────────
//  ZONE MODEL
//  Fields:
//    id        — unique identifier  ('zone1' | 'zone2')
//    name      — user-editable display name
//    priority  — integer used for load-shedding order (1 = highest)
//    isActive  — zone master on/off
//    devices   — mutable list of Device objects
//
//  Computed:
//    totalConsumption — sum of power (W) for ON devices only
//    deviceCount      — total number of devices (on + off)
// ─────────────────────────────────────────────────────────────────

import 'package:greenvolt/models/device_model.dart';

class Zone {
  final String id;
  String name;
  int priority;
  bool isActive;
  final List<Device> devices;

  Zone({
    required this.id,
    required this.name,
    required this.priority,
    this.isActive = true,
    List<Device>? devices,
  }) : devices = devices ?? [];

  /// Real-time consumption — zone must be active AND device must be ON.
  /// Returns 0 immediately when the zone master switch is OFF.
  double get totalConsumption => isActive
      ? devices.where((d) => d.isOn).fold(0.0, (sum, d) => sum + d.power)
      : 0.0;

  int get deviceCount => devices.length;
}
