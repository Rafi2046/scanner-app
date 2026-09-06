import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/tools/widgets/merge_library_pick_tile.dart';
import 'package:scanner_app/views/tools/widgets/merge_library_preview_dialog.dart';

/// Premium bottom sheet to pick library PDFs with large page previews.
class MergeLibraryPickerSheet extends StatefulWidget {
  const MergeLibraryPickerSheet({
    super.key,
    required this.documents,
    required this.onConfirm,
  });

  final List<ScannedDocument> documents;
  final ValueChanged<List<ScannedDocument>> onConfirm;

  static Future<void> show({
    required BuildContext context,
    required List<ScannedDocument> documents,
    required ValueChanged<List<ScannedDocument>> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => MergeLibraryPickerSheet(
        documents: documents,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<MergeLibraryPickerSheet> createState() =>
      _MergeLibraryPickerSheetState();
}

class _MergeLibraryPickerSheetState extends State<MergeLibraryPickerSheet> {
  final Set<String> _selectedIds = <String>{};

  bool get _allSelected =>
      _selectedIds.length == widget.documents.length &&
      widget.documents.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double maxH = MediaQuery.of(context).size.height * 0.88;
    final int selectedCount = _selectedIds.length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.96),
                const Color(0xFFF4F6FA),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _Header(
                  documentCount: widget.documents.length,
                  selectedCount: selectedCount,
                  allSelected: _allSelected,
                  onToggleAll: () {
                    setState(() {
                      if (_allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(
                          widget.documents.map((ScannedDocument d) => d.id),
                        );
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    shrinkWrap: true,
                    itemCount: widget.documents.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppConstants.spaceSm),
                    itemBuilder: (BuildContext context, int index) {
                      final ScannedDocument doc = widget.documents[index];
                      final bool selected = _selectedIds.contains(doc.id);
                      return MergeLibraryPickTile(
                        document: doc,
                        selected: selected,
                        onToggle: () {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(doc.id);
                            } else {
                              _selectedIds.add(doc.id);
                            }
                          });
                          HapticFeedback.selectionClick();
                        },
                        onPreview: () => _openPreview(doc),
                      );
                    },
                  ),
                ),
                _FooterBar(
                  selectedCount: selectedCount,
                  onConfirm: selectedCount == 0
                      ? null
                      : () {
                          final List<ScannedDocument> picked = widget.documents
                              .where(
                                (ScannedDocument d) =>
                                    _selectedIds.contains(d.id),
                              )
                              .toList();
                          Navigator.of(context).pop();
                          widget.onConfirm(picked);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPreview(ScannedDocument doc) {
    final List<String> paths = doc.imagePaths
        .where((String p) => File(p).existsSync())
        .toList();
    MergeLibraryPreviewDialog.show(
      context: context,
      title: doc.title,
      imagePaths: paths,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.documentCount,
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
  });

  final int documentCount;
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF5B8AFF), AppTheme.primary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.layers,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Select from App Scans',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount == 0
                      ? '$documentCount scans ready · preview to pick'
                      : '$selectedCount selected · ready to merge',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onToggleAll,
            child: Text(
              allSelected ? 'Clear' : 'Select all',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({required this.selectedCount, required this.onConfirm});

  final int selectedCount;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onConfirm != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF5B8AFF), AppTheme.primary],
                  )
                : null,
            color: enabled ? null : const Color(0xFFE8EAED),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              child: Center(
                child: Text(
                  selectedCount == 0
                      ? 'Select Documents'
                      : 'Add $selectedCount '
                          '${selectedCount == 1 ? 'Document' : 'Documents'}',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
