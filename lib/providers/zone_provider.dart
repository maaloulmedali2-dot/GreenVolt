// ─────────────────────────────────────────────────────────────────
//  ZONE PROVIDER
//  Source of truth for the 2 fixed zones and all their devices.
//
//  State:
//    _zones — fixed list of Zone objects (zone1, zone2)
//
//  Zone ops:   renameZone · toggleZone · swapPriorities
//  Device ops: addDevice · removeDevice · toggleDevice · editDevice
//
//  Aggregates:
//    totalConsumption  — sum of ON-device power across all zones (W)
//    totalDeviceCount  — total devices across all zones
//
//  Load-shedding hook:
//    zonesBySheddingOrder — zones sorted highest-priority-last so
//    the lowest-priority zone can be cut first when overload occurs.
// ─────────────────────────────────────────────────────────────────

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:greenvolt/models/device_model.dart';
import 'package:greenvolt/models/zone_model.dart';

class ZoneProvider extends ChangeNotifier {
  final _cmdRef = FirebaseDatabase.instance.ref('system/commands');

  static String _rtdbKey(String zoneId) =>
      zoneId == 'zone1' ? 'Z1' : 'Z2';
  final List<Zone> _zones = [
    Zone(id: 'zone1', name: 'Zone 1', priority: 1),
    Zone(id: 'zone2', name: 'Zone 2', priority: 2),
  ];

  // ── Read ─────────────────────────────────────────────────────

  List<Zone> get zones => List.unmodifiable(_zones);

  Zone zoneById(String id) => _zones.firstWhere((z) => z.id == id);

  // ── Zone operations ──────────────────────────────────────────

  void renameZone(String id, String name) {
    zoneById(id).name = name;
    notifyListeners();
  }

  void toggleZone(String id) {
    final z = zoneById(id);
    z.isActive = !z.isActive;
    _cmdRef.update({_rtdbKey(id): z.isActive});
    notifyListeners();
  }

  /// Swaps priorities between zone1 and zone2.
  /// Used manually and reserved for load-shedding automation.
  void swapPriorities() {
    if (_zones.length < 2) return;
    final tmp = _zones[0].priority;
    _zones[0].priority = _zones[1].priority;
    _zones[1].priority = tmp;
    _cmdRef.update({
      'Z1priority': _zones[0].priority,
      'Z2priority': _zones[1].priority,
    });
    notifyListeners();
  }

  // ── Device operations ────────────────────────────────────────

  void addDevice(String zoneId, Device device) {
    zoneById(zoneId).devices.add(device);
    notifyListeners();
  }

  void removeDevice(String zoneId, String deviceId) {
    zoneById(zoneId).devices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
  }

  void toggleDevice(String zoneId, String deviceId) {
    final d = zoneById(zoneId).devices.firstWhere((d) => d.id == deviceId);
    d.isOn = !d.isOn;
    notifyListeners();
  }

  void editDevice(String zoneId, String deviceId, String name,
      double voltage, double intensity) {
    final d = zoneById(zoneId).devices.firstWhere((d) => d.id == deviceId);
    d.name = name;
    d.voltage = voltage;
    d.intensity = intensity;
    notifyListeners();
  }

  // ── Aggregates ───────────────────────────────────────────────

  /// Total active (ON) consumption across all zones in Watts.
  double get totalConsumption =>
      _zones.fold(0.0, (sum, z) => sum + z.totalConsumption);

  /// Total device count (ON + OFF) across all zones.
  int get totalDeviceCount => _zones.fold(0, (sum, z) => sum + z.deviceCount);

  // ── Load-shedding hook (future use) ─────────────────────────

  /// Zones sorted ascending by priority so the last entry is shed first
  /// (lowest priority = highest priority number = shed first).
  /// Call this method to determine which zone to cut when load exceeds
  /// a threshold.
  List<Zone> get zonesBySheddingOrder =>
      [..._zones]..sort((a, b) => a.priority.compareTo(b.priority));
}
