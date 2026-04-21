// ─────────────────────────────────────────────────────────────────
//  DEVICE MODEL
//  Stored fields:
//    id        — unique identifier
//    name      — display name
//    voltage   — rated voltage in Volts
//    intensity — rated current in Amps
//    isOn      — current on/off state
//
//  Computed:
//    power  — V × I  (Watts)
//
//  Only devices with isOn == true contribute to zone consumption.
// ─────────────────────────────────────────────────────────────────

class Device {
  final String id;
  String name;
  double voltage;   // V
  double intensity; // A
  bool isOn;

  Device({
    required this.id,
    required this.name,
    required this.voltage,
    required this.intensity,
    this.isOn = true,
  });

  /// Power in Watts — always V × I.
  double get power => voltage * intensity;
}
