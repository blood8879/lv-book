import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/widgets/app_snackbar.dart';

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
    if (_controller.isEmpty) {
      AppSnackbar.error(context, '서명을 입력해 주세요');
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    if (bytes == null) {
      AppSnackbar.error(context, '서명을 저장하지 못했습니다');
      return;
    }
    navigator.pop(base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('서명 입력'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '아래 영역에 손가락 또는 펜으로 서명하세요.',
              style: TextStyle(fontSize: 13),
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
          child: const Text('다시 쓰기'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _saveSignature, child: const Text('저장')),
      ],
    );
  }
}
