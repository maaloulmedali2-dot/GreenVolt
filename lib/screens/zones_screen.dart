import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:greenvolt/models/device_model.dart';
import 'package:greenvolt/models/zone_model.dart';
import 'package:greenvolt/providers/zone_provider.dart';
import 'package:greenvolt/theme/app_theme.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────
//  ZONES SCREEN
//  · 2 fixed zones managed via ZoneProvider (ChangeNotifier)
//  · Device model: id, name, power (W), isOn
//  · Zone totals update instantly on every toggle / add / remove
//  · Priority field is wired and ready for load-shedding logic
// ─────────────────────────────────────────────────────────────────

class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

  // ── Rename dialog ─────────────────────────────────────────────
  Future<void> _rename(
      BuildContext context, String zoneId, String current) async {
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: AppTheme.surface,
        title: Text('Rename Zone', style: AppTheme.bold(17)),
        content:
            EcField(ctrl: ctrl, hint: 'Zone name', icon: Icons.edit_rounded),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: AppTheme.body(14, color: AppTheme.textSec))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('Save',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      Provider.of<ZoneProvider>(context, listen: false)
          .renameZone(zoneId, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          EcHeader(
            title: 'Energy Zones',
            icon: Icons.layers_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 22),
                onPressed: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WelcomeScreen()));
                  }
                },
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: Consumer<ZoneProvider>(
              builder: (context, provider, _) {
                final z1 = provider.zoneById('zone1');
                final z2 = provider.zoneById('zone2');

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // Grand total banner
                    _TotalBanner(provider: provider),
                    const SizedBox(height: 16),

                    // Zone 1
                    _ZoneCard(
                      zoneId: 'zone1',
                      accentColor: AppTheme.accent,
                      gradColors: const [
                        Color(0xFF0D2318),
                        Color(0xFF1A4A2E),
                      ],
                      onRename: () => _rename(context, 'zone1', z1.name),
                    ),
                    const SizedBox(height: 16),

                    // Zone 2
                    _ZoneCard(
                      zoneId: 'zone2',
                      accentColor: const Color(0xFF448AFF),
                      gradColors: const [
                        Color(0xFF0D1A35),
                        Color(0xFF1A3060),
                      ],
                      onRename: () => _rename(context, 'zone2', z2.name),
                    ),
                  ],
                );
              },
            ),
          ),

          const EcNav(selected: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  TOTAL BANNER
// ─────────────────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  final ZoneProvider provider;
  const _TotalBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalConsumption;
    final devices = provider.totalDeviceCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2318), Color(0xFF1A3A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.deepShadow,
      ),
      child: Stack(
        children: [
          // Dot texture
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Active Consumption',
                      style: GoogleFonts.dmSans(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        total >= 1000
                            ? (total / 1000).toStringAsFixed(2)
                            : total.toStringAsFixed(0),
                        style: GoogleFonts.rajdhani(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                            height: 1),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(total >= 1000 ? 'kW' : 'W',
                            style: GoogleFonts.dmSans(
                                color: AppTheme.accentDim, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(children: [
              _miniStat('$devices', 'Devices', Icons.devices_rounded),
              const SizedBox(height: 10),
              _miniStat('2', 'Zones', Icons.layers_rounded),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String val, String lbl, IconData icon) => Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Text(val,
              style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(width: 4),
          Text(lbl,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: Colors.white54)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────
//  ZONE CARD  — expandable, device list, add/edit/remove
// ─────────────────────────────────────────────────────────────────

class _ZoneCard extends StatefulWidget {
  final String zoneId;
  final Color accentColor;
  final List<Color> gradColors;
  final VoidCallback onRename;

  const _ZoneCard({
    required this.zoneId,
    required this.accentColor,
    required this.gradColors,
    required this.onRename,
  });

  @override
  _ZoneCardState createState() => _ZoneCardState();
}

class _ZoneCardState extends State<_ZoneCard> {
  bool _expanded = true;

  ZoneProvider get _p => Provider.of<ZoneProvider>(context, listen: false);

  // ── Delete confirmation ───────────────────────────────────────
  Future<bool?> _confirmDelete() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Remove Device', style: AppTheme.bold(16)),
          content: Text('Remove this device from the zone?',
              style: AppTheme.body(14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: AppTheme.body(14))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Remove',
                  style:
                      GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ── Add / Edit device bottom sheet ────────────────────────────
  Future<void> _showDeviceDialog({Device? edit}) async {
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final voltCtrl = TextEditingController(
        text: edit != null ? edit.voltage.toStringAsFixed(0) : '');
    final ampCtrl = TextEditingController(
        text: edit != null ? edit.intensity.toStringAsFixed(2) : '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final v = double.tryParse(voltCtrl.text) ?? 0.0;
          final a = double.tryParse(ampCtrl.text) ?? 0.0;
          final previewW = v * a;

          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Text(
                    edit == null
                        ? 'Add Device to ${_p.zoneById(widget.zoneId).name}'
                        : 'Edit Device',
                    style: AppTheme.bold(18),
                  ),
                  Text('Enter electrical specs below',
                      style: AppTheme.body(13)),
                  const SizedBox(height: 20),

                  // Name
                  EcField(
                    ctrl: nameCtrl,
                    hint: 'Device name (e.g. LED Light)',
                    icon: Icons.devices_rounded,
                  ),
                  const SizedBox(height: 12),

                  // Voltage + Intensity row
                  Row(children: [
                    Expanded(
                      child: EcField(
                        ctrl: voltCtrl,
                        hint: 'Voltage',
                        icon: Icons.electric_bolt_rounded,
                        type: TextInputType.number,
                        suffix: 'V',
                        onChanged: (_) => setSt(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: EcField(
                        ctrl: ampCtrl,
                        hint: 'Intensity',
                        icon: Icons.electrical_services_rounded,
                        type: TextInputType.number,
                        suffix: 'A',
                        onChanged: (_) => setSt(() {}),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Live V × A = W preview
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (previewW > 0
                              ? widget.accentColor
                              : AppTheme.border)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (previewW > 0
                                ? widget.accentColor
                                : AppTheme.border)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _calcChip('Power', '${previewW.toStringAsFixed(1)} W',
                            widget.accentColor, 'V × A'),
                        Container(
                            width: 1, height: 36, color: AppTheme.border),
                        _calcChip(
                            'Voltage', '${v.toStringAsFixed(0)} V',
                            AppTheme.solar, 'volts'),
                        Container(
                            width: 1, height: 36, color: AppTheme.border),
                        _calcChip(
                            'Current', '${a.toStringAsFixed(2)} A',
                            const Color(0xFF448AFF), 'amps'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  EcButton(
                    text: edit == null ? 'Add Device' : 'Save Changes',
                    icon: edit == null
                        ? Icons.add_rounded
                        : Icons.check_rounded,
                    color: widget.accentColor,
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final volt = double.tryParse(voltCtrl.text) ?? 0;
                      final amp = double.tryParse(ampCtrl.text) ?? 0;
                      if (name.isEmpty || volt <= 0 || amp <= 0) return;

                      if (edit == null) {
                        _p.addDevice(
                          widget.zoneId,
                          Device(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: name,
                            voltage: volt,
                            intensity: amp,
                          ),
                        );
                      } else {
                        _p.editDevice(
                            widget.zoneId, edit.id, name, volt, amp);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _calcChip(
      String label, String value, Color color, String formula) {
    return Column(children: [
      Text(formula,
          style: AppTheme.body(9, color: color.withValues(alpha: 0.6))),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.rajdhani(
              fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: AppTheme.body(10)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ZoneProvider>(
      builder: (context, provider, _) {
        final zone = provider.zoneById(widget.zoneId);
        final total = zone.totalConsumption;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── Zone header (dark gradient) ─────────────────
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: widget.gradColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                            child: CustomPaint(
                                painter: _DotPainter())),
                      ),
                      Row(children: [
                        // Priority circle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor
                                .withValues(alpha: 0.2),
                            border: Border.all(
                                color: widget.accentColor
                                    .withValues(alpha: 0.5),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text('P${zone.priority}',
                                style: GoogleFonts.rajdhani(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: widget.accentColor)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(zone.name,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Row(children: [
                                _headerChip(
                                    '${zone.deviceCount} device${zone.deviceCount == 1 ? '' : 's'}',
                                    Icons.devices_rounded),
                                const SizedBox(width: 8),
                                _headerChip(
                                    '${total.toStringAsFixed(0)} W active',
                                    Icons.bolt_rounded),
                              ]),
                            ],
                          ),
                        ),

                        // Zone master toggle
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: zone.isActive,
                            activeThumbColor: widget.accentColor,
                            activeTrackColor: widget.accentColor
                                .withValues(alpha: 0.3),
                            inactiveThumbColor: Colors.white38,
                            inactiveTrackColor: Colors.white12,
                            onChanged: (_) =>
                                provider.toggleZone(zone.id),
                          ),
                        ),

                        // Expand chevron
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Action bar ────────────────────────────────────
              Container(
                color: AppTheme.surfaceAlt,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(children: [
                  _barBtn(Icons.edit_outlined, 'Rename',
                      widget.onRename),
                  const SizedBox(width: 8),
                  _barBtn(Icons.add_rounded, 'Add Device',
                      () => _showDeviceDialog(),
                      accent: true),
                  const Spacer(),
                  _priorityPill(zone.priority, provider),
                ]),
              ),

              // ── Device list (collapsible) ─────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _DeviceList(
                  zone: zone,
                  accentColor: widget.accentColor,
                  onToggle: (id) =>
                      provider.toggleDevice(zone.id, id),
                  onEdit: (device) =>
                      _showDeviceDialog(edit: device),
                  onDelete: (id) async {
                    final ok = await _confirmDelete();
                    if (ok == true) {
                      provider.removeDevice(zone.id, id);
                    }
                  },
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerChip(String label, IconData icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 11),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _priorityPill(int priority, ZoneProvider provider) {
    final isPrimary = priority == 1;
    final color = isPrimary ? widget.accentColor : AppTheme.warning;
    return GestureDetector(
      onTap: provider.swapPriorities,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isPrimary ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: color.withValues(
                  alpha: isPrimary ? 0.4 : 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isPrimary
                ? Icons.star_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            isPrimary ? 'Priority 1' : 'Priority 2',
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ]),
      ),
    );
  }

  Widget _barBtn(IconData icon, String label, VoidCallback onTap,
      {bool accent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent
              ? widget.accentColor.withValues(alpha: 0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: accent
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color:
                  accent ? widget.accentColor : AppTheme.textSec,
              size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent
                      ? widget.accentColor
                      : AppTheme.textSec)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DEVICE LIST
// ─────────────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  final Zone zone;
  final Color accentColor;
  final void Function(String deviceId) onToggle;
  final void Function(Device device) onEdit;
  final void Function(String deviceId) onDelete;

  const _DeviceList({
    required this.zone,
    required this.accentColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (zone.devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.devices_outlined,
              size: 36, color: AppTheme.border),
          const SizedBox(height: 8),
          Text('No devices yet',
              style: AppTheme.label(14, color: AppTheme.textSec)),
          const SizedBox(height: 4),
          Text('Tap "Add Device" to get started.',
              style: AppTheme.body(12)),
        ]),
      );
    }

    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Text('Device', style: AppTheme.body(11))),
            _colHead('V'),
            _colHead('A'),
            _colHead('W'),
            const SizedBox(width: 92),
          ]),
        ),
        const Divider(height: 1),
        // Device rows
        ...zone.devices.map(
          (device) => _DeviceRow(
            device: device,
            accentColor: accentColor,
            onToggle: () => onToggle(device.id),
            onEdit: () => onEdit(device),
            onDelete: () => onDelete(device.id),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _colHead(String t) => SizedBox(
        width: 46,
        child: Text(t,
            textAlign: TextAlign.center, style: AppTheme.body(11)),
      );
}

// ─────────────────────────────────────────────────────────────────
//  DEVICE ROW
// ─────────────────────────────────────────────────────────────────

class _DeviceRow extends StatelessWidget {
  final Device device;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DeviceRow({
    required this.device,
    required this.accentColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.5))),
        color: isOn ? Colors.white : AppTheme.surfaceAlt,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(children: [
          // Name + on/off dot
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOn ? accentColor : AppTheme.border,
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 4)
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(device.name,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOn
                            ? AppTheme.textPri
                            : AppTheme.textSec),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

          // V
          _numCell(device.voltage.toStringAsFixed(0),
              isOn ? AppTheme.solar : AppTheme.textSec),
          // A
          _numCell(device.intensity.toStringAsFixed(2),
              isOn ? const Color(0xFF448AFF) : AppTheme.textSec),
          // W
          _numCell(device.power.toStringAsFixed(0),
              isOn ? accentColor : AppTheme.textSec),

          // Actions
          SizedBox(
            width: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn(
                  isOn
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  isOn ? accentColor : AppTheme.textSec,
                  isOn
                      ? accentColor.withValues(alpha: 0.12)
                      : AppTheme.surfaceAlt,
                  isOn
                      ? accentColor.withValues(alpha: 0.3)
                      : AppTheme.border,
                  onToggle,
                ),
                const SizedBox(width: 4),
                _actionBtn(Icons.edit_rounded, AppTheme.textSec,
                    AppTheme.surfaceAlt, AppTheme.border, onEdit),
                const SizedBox(width: 4),
                _actionBtn(
                  Icons.delete_outline_rounded,
                  AppTheme.danger,
                  AppTheme.danger.withValues(alpha: 0.08),
                  AppTheme.danger.withValues(alpha: 0.25),
                  onDelete,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _numCell(String val, Color color) => SizedBox(
        width: 46,
        child: Text(val,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _actionBtn(IconData icon, Color iconColor, Color bg,
      Color border, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: iconColor, size: 15),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DOT GRID PAINTER  (shared with zone card headers)
// ─────────────────────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const s = 18.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.3, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
