import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/models/timestamp_config.dart';
import 'package:scanner_app/providers/timestamp_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/timestamp_overlay_card.dart';

/// Modal bottom sheet for customizing Timestamp templates and content.
class EditTimestampBottomSheet extends ConsumerStatefulWidget {
  const EditTimestampBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171E),
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const EditTimestampBottomSheet(),
    );
  }

  @override
  ConsumerState<EditTimestampBottomSheet> createState() => _EditTimestampBottomSheetState();
}

class _EditTimestampBottomSheetState extends ConsumerState<EditTimestampBottomSheet> {
  int _selectedTab = 0; // 0: Templates, 1: Content

  static const Color accentTeal = Color(0xFF00C292);

  void _showEditLocationDialog(BuildContext context, String current) {
    final TextEditingController controller = TextEditingController(text: current);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F29),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Location',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Shikdar Pharmacy, Office HQ',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F1218),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentTeal, width: 1.5),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(timestampConfigProvider.notifier).setLocationText(controller.text);
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showEditTagDialog(BuildContext context, String current) {
    final TextEditingController controller = TextEditingController(text: current);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F29),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Remark / Tag',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Verified on-site, Inspection Done',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F1218),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentTeal, width: 1.5),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(timestampConfigProvider.notifier).setCustomTag(controller.text);
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TimestampConfig config = ref.watch(timestampConfigProvider);
    final notifier = ref.read(timestampConfigProvider.notifier);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // Handle bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title & close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Edit Timestamp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white70, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Tab Switcher (Templates | Content)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF222630),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: <Widget>[
                    _buildSegment(label: 'Templates', index: 0),
                    _buildSegment(label: 'Content', index: 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildTemplatesGrid(config, notifier)
                  : _buildContentTab(config, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment({required String label, required int index}) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF383E4C) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Templates Tab (2-column rich grid)
  Widget _buildTemplatesGrid(TimestampConfig config, TimestampConfigNotifier notifier) {
    final DateTime sampleTime = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.25,
      ),
      itemCount: TimestampTemplateType.values.length,
      itemBuilder: (BuildContext context, int index) {
        final TimestampTemplateType t = TimestampTemplateType.values[index];
        final bool isSelected = t == config.template;
        final TimestampConfig previewConfig = config.copyWith(template: t);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.setTemplate(t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentTeal : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accentTeal.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Mini preview container
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TimestampOverlayCard(
                        config: previewConfig,
                        fixedTime: sampleTime,
                        isMini: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(
                          color: isSelected ? accentTeal : Colors.white,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      const Icon(LucideIcons.check, color: accentTeal, size: 14),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Content Tab (Toggles & Custom inputs)
  Widget _buildContentTab(TimestampConfig config, TimestampConfigNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        // Time row
        _buildContentTile(
          icon: LucideIcons.clock,
          title: 'Time Format',
          subtitle: config.is24Hour ? '24-hour (14:30)' : '12-hour (02:30 PM)',
          trailing: Switch.adaptive(
            value: config.is24Hour,
            activeTrackColor: accentTeal,
            onChanged: (bool val) => notifier.toggle24Hour(val),
          ),
        ),

        const SizedBox(height: 10),

        // Seconds row
        _buildContentTile(
          icon: LucideIcons.timer,
          title: 'Display Seconds',
          subtitle: config.showSeconds ? 'Showing seconds (10:40:15)' : 'Hidden (10:40)',
          trailing: Switch.adaptive(
            value: config.showSeconds,
            activeTrackColor: accentTeal,
            onChanged: (bool val) => notifier.toggleShowSeconds(val),
          ),
        ),

        const SizedBox(height: 10),

        // Location row
        _buildContentTile(
          icon: LucideIcons.mapPin,
          title: 'Location Tag',
          subtitle: config.showLocation ? config.locationText : 'Hidden',
          onTap: () => _showEditLocationDialog(context, config.locationText),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(LucideIcons.edit2, color: accentTeal, size: 17),
                onPressed: () => _showEditLocationDialog(context, config.locationText),
                tooltip: 'Change location',
              ),
              Switch.adaptive(
                value: config.showLocation,
                activeTrackColor: accentTeal,
                onChanged: (bool val) => notifier.toggleShowLocation(val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Custom Tag / Remarks
        _buildContentTile(
          icon: LucideIcons.tag,
          title: 'Custom Note / Tag',
          subtitle: config.showTag ? config.customTag : 'Hidden',
          onTap: () => _showEditTagDialog(context, config.customTag),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(LucideIcons.edit2, color: accentTeal, size: 17),
                onPressed: () => _showEditTagDialog(context, config.customTag),
                tooltip: 'Change tag',
              ),
              Switch.adaptive(
                value: config.showTag,
                activeTrackColor: accentTeal,
                onChanged: (bool val) => notifier.toggleShowTag(val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Verified by watermark
        _buildContentTile(
          icon: LucideIcons.shieldCheck,
          title: 'Security Watermark',
          subtitle: config.showVerified ? config.verifiedBy : 'Disabled',
          trailing: Switch.adaptive(
            value: config.showVerified,
            activeTrackColor: accentTeal,
            onChanged: (bool val) => notifier.toggleShowVerified(val),
          ),
        ),

        const SizedBox(height: 10),

        // Stamp Size / Scale Slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1F2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.scaling, color: accentTeal, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Stamp Size',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current: ${(config.scale * 100).toInt()}% • Pinch on camera or drag slider',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => notifier.setScale(1.0),
                    icon: const Icon(LucideIcons.rotateCcw, size: 13, color: accentTeal),
                    label: const Text(
                      '100%',
                      style: TextStyle(
                        color: accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: accentTeal.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Text('65%', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentTeal,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: accentTeal,
                        overlayColor: accentTeal.withValues(alpha: 0.2),
                        trackHeight: 3.5,
                      ),
                      child: Slider(
                        value: config.scale.clamp(0.65, 1.8),
                        min: 0.65,
                        max: 1.8,
                        divisions: 23,
                        onChanged: (double val) => notifier.setScale(val),
                      ),
                    ),
                  ),
                  const Text('180%', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Stamp Placement Row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1F2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.move, color: accentTeal, size: 19),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Quick Placement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Drag anywhere on camera, or tap below',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCcw, color: accentTeal, size: 16),
                    tooltip: 'Reset position & scale',
                    onPressed: () => notifier.resetPositionAndScale(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildPositionChip('Bottom-Left', const Offset(0.04, 0.72), config, notifier),
                  _buildPositionChip('Bottom-Right', const Offset(0.55, 0.72), config, notifier),
                  _buildPositionChip('Top-Left', const Offset(0.04, 0.08), config, notifier),
                  _buildPositionChip('Top-Right', const Offset(0.55, 0.08), config, notifier),
                  _buildPositionChip('Center', const Offset(0.28, 0.40), config, notifier),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionChip(
    String label,
    Offset position,
    TimestampConfig config,
    TimestampConfigNotifier notifier,
  ) {
    final bool isSelected = (config.positionRatio - position).distance < 0.06;
    return GestureDetector(
      onTap: () => notifier.setPositionRatio(position),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentTeal.withValues(alpha: 0.18) : const Color(0xFF131720),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentTeal : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accentTeal : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentTeal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentTeal, size: 19),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
      ),
    );
  }
}
