import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../l10n/l10n.dart';

/// A dialog that lets the user draw a handwritten signature and returns it as
/// a base64-encoded PNG string. Returns null when cancelled.
class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SignaturePadDialog(),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    if (_controller.isEmpty) {
      AppSnackbar.error(context, l10n.proSignatureEmptyError);
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    if (bytes == null) {
      AppSnackbar.error(context, l10n.proSignatureSaveError);
      return;
    }
    navigator.pop(base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.proSignatureDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.proSignatureDialogHint,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Signature(
                controller: _controller,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _controller.clear(),
          child: Text(l10n.proSignatureClear),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.coreCancel),
        ),
        FilledButton(onPressed: _saveSignature, child: Text(l10n.coreSave)),
      ],
    );
  }
}
