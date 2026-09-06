import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/models/timestamp_config.dart';

/// Renders the live or preview timestamp card across 6 modern, distinct templates.
class TimestampOverlayCard extends StatefulWidget {
  const TimestampOverlayCard({
    super.key,
    required this.config,
    this.fixedTime,
    this.isMini = false,
  });

  final TimestampConfig config;
  final DateTime? fixedTime;
  final bool isMini;

  @override
  State<TimestampOverlayCard> createState() => _TimestampOverlayCardState();
}

class _TimestampOverlayCardState extends State<TimestampOverlayCard> {
  Timer? _ticker;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.fixedTime ?? DateTime.now();
    if (widget.fixedTime == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TimestampOverlayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedTime != null) {
      _now = widget.fixedTime!;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final bool is24 = widget.config.is24Hour;
    final bool secs = widget.config.showSeconds;

    if (is24) {
      return secs ? DateFormat('HH:mm:ss').format(_now) : DateFormat('HH:mm').format(_now);
    } else {
      return secs ? DateFormat('hh:mm:ss a').format(_now) : DateFormat('hh:mm a').format(_now);
    }
  }

  String _formatDate() {
    return DateFormat('EEEE | MM/dd/yy').format(_now);
  }

  String _formatIsoDate() {
    return DateFormat('yyyy-MM-dd').format(_now);
  }

  @override
  Widget build(BuildContext context) {
    final String timeStr = _formatTime();
    final String dateStr = _formatDate();
    final bool isMini = widget.isMini;

    return switch (widget.config.template) {
      TimestampTemplateType.minimal => _buildMinimalTemplate(timeStr, dateStr, isMini),
      TimestampTemplateType.onSite => _buildOnSiteTemplate(timeStr, isMini),
      TimestampTemplateType.clockIn => _buildClockInTemplate(timeStr, isMini),
      TimestampTemplateType.digitalLcd => _buildDigitalLcdTemplate(timeStr, isMini),
      TimestampTemplateType.officialStamp => _buildOfficialStampTemplate(timeStr, isMini),
      TimestampTemplateType.travelPin => _buildTravelPinTemplate(timeStr, dateStr, isMini),
    };
  }

  // 1. Minimal Clean (CamScanner Pro inspired, refined with dark glassmorphism)
  Widget _buildMinimalTemplate(String time, String date, bool isMini) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMini ? 8 : 14,
        vertical: isMini ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isMini ? 0.75 : 0.60),
        borderRadius: BorderRadius.circular(isMini ? 8 : 12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMini ? 15 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: isMini ? 8.5 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.config.showLocation) ...<Widget>[
            SizedBox(height: isMini ? 2 : 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.mapPin,
                  size: isMini ? 8 : 12,
                  color: const Color(0xFFFF5252),
                ),
                SizedBox(width: isMini ? 3 : 5),
                Flexible(
                  child: Text(
                    widget.config.locationText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMini ? 8 : 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (widget.config.showVerified && !isMini) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 11,
                  color: Color(0xFF00D2A0),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.config.verifiedBy,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. On-Site Pro (Cobalt banner with structured inspection grid)
  Widget _buildOnSiteTemplate(String time, bool isMini) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10141E).withValues(alpha: isMini ? 0.95 : 0.85),
        borderRadius: BorderRadius.circular(isMini ? 8 : 12),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.45), width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMini ? 7 : 11),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMini ? 6 : 10,
                vertical: isMini ? 3 : 5,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF1D4ED8), Color(0xFF2563EB)],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(LucideIcons.hardHat, color: Colors.white, size: isMini ? 9 : 13),
                  SizedBox(width: isMini ? 3 : 6),
                  Text(
                    'ON-SITE INSPECTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMini ? 7.5 : 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMini ? 8 : 12,
                vertical: isMini ? 4 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _gridRow('Time:', time, isMini, highlight: true),
                  SizedBox(height: isMini ? 2 : 4),
                  _gridRow('Date:', _formatIsoDate(), isMini),
                  if (widget.config.showLocation) ...<Widget>[
                    SizedBox(height: isMini ? 2 : 4),
                    _gridRow('Location:', widget.config.locationText, isMini),
                  ],
                  if (widget.config.showTag && !isMini) ...<Widget>[
                    const SizedBox(height: 4),
                    _gridRow('Status:', widget.config.customTag, isMini, tagColor: const Color(0xFF38BDF8)),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _gridRow(String label, String value, bool isMini, {bool highlight = false, Color? tagColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: isMini ? 38 : 54,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: isMini ? 7 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: tagColor ?? (highlight ? Colors.white : Colors.white70),
              fontSize: isMini ? 7.5 : (highlight ? 11 : 10),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 3. Clock-In (Emerald Punch Card Record)
  Widget _buildClockInTemplate(String time, bool isMini) {
    return Container(
      padding: EdgeInsets.all(isMini ? 6 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1412).withValues(alpha: isMini ? 0.95 : 0.82),
        borderRadius: BorderRadius.circular(isMini ? 8 : 12),
        border: Border.all(color: const Color(0xFF00C292).withValues(alpha: 0.5), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMini ? 4 : 7, vertical: isMini ? 1.5 : 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C292),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'CLOCK-IN',
                  style: TextStyle(
                    color: const Color(0xFF06281E),
                    fontSize: isMini ? 6.5 : 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd • EEE').format(_now).toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF00C292),
                  fontSize: isMini ? 6.5 : 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: isMini ? 3 : 6),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMini ? 14 : 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
              height: 1.05,
            ),
          ),
          if (widget.config.showLocation) ...<Widget>[
            SizedBox(height: isMini ? 2 : 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(LucideIcons.mapPin, size: isMini ? 7 : 11, color: const Color(0xFF00C292)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.config.locationText,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMini ? 7.5 : 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. Digital Clock (Glowing 7-segment retro LCD)
  Widget _buildDigitalLcdTemplate(String time, bool isMini) {
    const Color lcdColor = Color(0xFF00FFB2);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMini ? 8 : 12,
        vertical: isMini ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF060D0A).withValues(alpha: isMini ? 0.95 : 0.88),
        borderRadius: BorderRadius.circular(isMini ? 6 : 10),
        border: Border.all(color: lcdColor.withValues(alpha: 0.6), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: lcdColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                DateFormat('yyyy/MM/dd').format(_now),
                style: TextStyle(
                  color: lcdColor.withValues(alpha: 0.75),
                  fontSize: isMini ? 7 : 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEE').format(_now).toUpperCase(),
                style: TextStyle(
                  color: lcdColor,
                  fontSize: isMini ? 7 : 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: isMini ? 2 : 4),
          Text(
            time,
            style: TextStyle(
              color: lcdColor,
              fontSize: isMini ? 16 : 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
              shadows: <Shadow>[
                Shadow(
                  color: lcdColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          if (widget.config.showLocation) ...<Widget>[
            SizedBox(height: isMini ? 2 : 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(LucideIcons.crosshair, size: isMini ? 7 : 10, color: lcdColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.config.locationText,
                    style: TextStyle(
                      color: lcdColor.withValues(alpha: 0.85),
                      fontSize: isMini ? 7 : 9.5,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 5. Official Stamp (Gold Notarized Security Seal)
  Widget _buildOfficialStampTemplate(String time, bool isMini) {
    const Color gold = Color(0xFFF59E0B);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMini ? 8 : 12,
        vertical: isMini ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF140E04).withValues(alpha: isMini ? 0.95 : 0.85),
        borderRadius: BorderRadius.circular(isMini ? 6 : 10),
        border: Border.all(color: gold.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(LucideIcons.award, size: isMini ? 9 : 13, color: gold),
              const SizedBox(width: 5),
              Text(
                'VERIFIED TIMESTAMP',
                style: TextStyle(
                  color: gold,
                  fontSize: isMini ? 7 : 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: isMini ? 2 : 4),
          Text(
            '$time • ${_formatIsoDate()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMini ? 9 : 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          if (widget.config.showLocation) ...<Widget>[
            SizedBox(height: isMini ? 2 : 3),
            Text(
              '📍 ${widget.config.locationText}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isMini ? 7 : 9.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!isMini) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'AUTH: CS-STAMP-SECURE-940',
              style: TextStyle(
                color: gold.withValues(alpha: 0.6),
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Travel Pin (Weather & Compact Travel Pill)
  Widget _buildTravelPinTemplate(String time, String date, bool isMini) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMini ? 8 : 12,
        vertical: isMini ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E28).withValues(alpha: isMini ? 0.95 : 0.8),
        borderRadius: BorderRadius.circular(isMini ? 12 : 20),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            LucideIcons.sun,
            size: isMini ? 14 : 22,
            color: const Color(0xFFFBBF24),
          ),
          SizedBox(width: isMini ? 6 : 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMini ? 11 : 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '28°C',
                    style: TextStyle(
                      color: const Color(0xFFFBBF24),
                      fontSize: isMini ? 8 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (widget.config.showLocation)
                Text(
                  widget.config.locationText,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMini ? 7.5 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
