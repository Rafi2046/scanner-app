import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Full-screen-ish dark preview for a library scan (multi-page swipe).
class MergeLibraryPreviewDialog extends StatefulWidget {
  const MergeLibraryPreviewDialog({
    super.key,
    required this.title,
    required this.imagePaths,
  });

  final String title;
  final List<String> imagePaths;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<String> imagePaths,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close preview',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) {
        return MergeLibraryPreviewDialog(
          title: title,
          imagePaths: imagePaths,
        );
      },
      transitionBuilder: (_, Animation<double> anim, _, Widget child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MergeLibraryPreviewDialog> createState() =>
      _MergeLibraryPreviewDialogState();
}

class _MergeLibraryPreviewDialogState extends State<MergeLibraryPreviewDialog> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final bool multi = widget.imagePaths.length > 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF14161C),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                            if (multi)
                              Text(
                                'Page ${_page + 1} of ${widget.imagePaths.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          LucideIcons.x,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: widget.imagePaths.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(56),
                          child: Icon(
                            LucideIcons.fileText,
                            size: 64,
                            color: Colors.white24,
                          ),
                        )
                      : PageView.builder(
                          itemCount: widget.imagePaths.length,
                          onPageChanged: (int i) => setState(() => _page = i),
                          itemBuilder: (_, int i) {
                            return InteractiveViewer(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(widget.imagePaths[i]),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (multi)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        widget.imagePaths.length,
                        (int i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
