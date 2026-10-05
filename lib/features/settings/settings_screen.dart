import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../l10n/l10n.dart';
import '../ads/ad_providers.dart';
import '../pro/pro_pdf_settings_screen.dart';
import '../purchase/purchase_controller.dart';
import '../purchase/purchase_providers.dart';
import '../../core/constants/app_constants.dart';
import '../fieldbook/domain/misclosure.dart';
import 'misclosure_tolerance_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final adsRemovedAsync = ref.watch(adsRemovedProvider);
    final purchaseController = ref.watch(purchaseControllerProvider);
    // Select on the message serial: the ChangeNotifier instance is the same
    // object for previous/next, so comparing `previous.message` never fires.
    // Ads-removed state is refreshed app-wide by the controller itself.
    ref.listen<(int, PurchaseNotice?)>(
      purchaseControllerProvider.select(
        (controller) => (controller.messageSerial, controller.notice),
      ),
      (previous, next) {
        final notice = next.$2;
        if (notice == null || next.$1 == previous?.$1) return;
        final message = notice.localizedMessage(context.l10n);
        if (notice.isError) {
          AppSnackbar.error(context, message);
        } else {
          AppSnackbar.success(context, message);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          AppConstants.quickMemoFabListBottomPadding(context),
        ),
        children: [
          _ProPurchasePanel(
            adsRemovedAsync: adsRemovedAsync,
            purchaseController: purchaseController,
          ),
          const SizedBox(height: 12),
          _SectionHeader(title: l10n.settingsPurchaseStatusSection),
          adsRemovedAsync.when(
            loading: () => _StatusTile(
              icon: Icons.sync,
              title: l10n.settingsAdsRemovedChecking,
              subtitle: l10n.settingsAdsRemovedCheckingSubtitle,
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(l10n.settingsAdsRemovedLoadError),
              subtitle: Text('$error'),
            ),
            data: (adsRemoved) => Opacity(
              // 읽기전용(조작 불가) 스위치임을 시각적으로 dim 처리.
              opacity: 0.55,
              child: SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.line),
                ),
                tileColor: colors.panel,
                secondary: Icon(
                  adsRemoved ? Icons.verified : Icons.workspace_premium,
                ),
                title: Text(l10n.settingsRemoveAdsTitle),
                subtitle: Text(
                  adsRemoved
                      ? l10n.settingsAdsRemovedActiveSubtitle
                      : l10n.settingsAdsRemovedInactiveSubtitle,
                ),
                value: adsRemoved,
                onChanged: null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.line),
            ),
            tileColor: colors.panel,
            leading: const Icon(Icons.restore),
            title: Text(l10n.settingsRestorePurchaseTitle),
            subtitle: Text(
              purchaseController.purchasePending
                  ? l10n.settingsRestorePurchasePendingSubtitle
                  : l10n.settingsRestorePurchaseSubtitle,
            ),
            onTap: purchaseController.purchasePending
                ? null
                : purchaseController.restorePurchases,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: l10n.settingsDocumentSection),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.line),
            ),
            tileColor: colors.panel,
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.settingsPdfSettingsTitle),
            subtitle: Text(l10n.settingsPdfSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProPdfSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: l10n.settingsCheckSection),
          const _LengthUnitTile(),
          const SizedBox(height: 8),
          const _MisclosureToleranceTile(),
          const SizedBox(height: 8),
          _SectionHeader(title: l10n.adsPolicySection),
          _StatusTile(
            icon: Icons.view_stream_outlined,
            title: l10n.adsPolicyBannerTitle,
            subtitle: l10n.adsPolicyBannerSubtitle,
          ),
          const SizedBox(height: 8),
          _StatusTile(
            icon: Icons.ios_share,
            title: l10n.adsPolicyExportTitle,
            subtitle: l10n.adsPolicyExportSubtitle,
          ),
        ],
      ),
    );
  }
}

class _ProPurchasePanel extends StatelessWidget {
  final AsyncValue<bool> adsRemovedAsync;
  final PurchaseController purchaseController;

  const _ProPurchasePanel({
    required this.adsRemovedAsync,
    required this.purchaseController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final isPro = adsRemovedAsync.valueOrNull == true;
    final isBusy =
        purchaseController.loading || purchaseController.purchasePending;
    final price = purchaseController.proProduct?.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPro ? Icons.verified : Icons.workspace_premium,
                  color: const Color(0xFF101010),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? l10n.proActiveTitle : l10n.coreAppProName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? l10n.proActiveSubtitle
                          : price == null
                          ? l10n.proPitchSubtitle
                          : l10n.proPriceOneTimePurchase(price),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FeaturePill(
                label: l10n.proFeatureNoAds,
                background: colors.darkSurface2,
              ),
              _FeaturePill(
                label: l10n.proFeatureBenchmarkPhotoLocation,
                background: colors.darkSurface2,
              ),
              _FeaturePill(
                label: l10n.proFeatureBulkExport,
                background: colors.darkSurface2,
              ),
              _FeaturePill(
                label: l10n.proFeatureSummaryReport,
                background: colors.darkSurface2,
              ),
            ],
          ),
          if (!isPro) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF101010),
                  minimumSize: const Size(0, 48),
                ),
                onPressed: isBusy ? null : purchaseController.buyPro,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(isBusy ? l10n.coreProcessing : l10n.proBuyButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final Color background;

  const _FeaturePill({required this.label, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      tileColor: colors.panel,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appColors.subtext,
        ),
      ),
    );
  }
}

String misclosureToleranceSummary(
  AppLocalizations l10n,
  MisclosureTolerance tolerance,
) => switch (tolerance.mode) {
  MisclosureToleranceMode.fixed => l10n.settingsToleranceFixedSummary(
    formatToleranceValue(tolerance.fixedEntry),
    tolerance.unit.toleranceSymbol,
  ),
  MisclosureToleranceMode.sqrtSetups => l10n.settingsToleranceSqrtSummary(
    formatToleranceValue(tolerance.coefficientEntry),
    tolerance.unit.toleranceSymbol,
  ),
};

/// 'Metres (m)' / 'Feet (ft)'.
String lengthUnitName(AppLocalizations l10n, LengthUnit unit) => switch (unit) {
  LengthUnit.metres => l10n.settingsUnitMetres,
  LengthUnit.feet => l10n.settingsUnitFeet,
};

Future<void> _saveTolerance(
  BuildContext context,
  WidgetRef ref,
  MisclosureTolerance updated,
) async {
  final l10n = context.l10n;
  try {
    await ref.read(misclosureToleranceRepositoryProvider).save(updated);
    ref.invalidate(misclosureToleranceProvider);
    if (context.mounted) AppSnackbar.success(context, l10n.coreSaved);
  } catch (error) {
    if (context.mounted) {
      AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
    }
  }
}

/// App length unit (labels only; numbers are never converted).
class _LengthUnitTile extends ConsumerWidget {
  const _LengthUnitTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final tolerance =
        ref.watch(misclosureToleranceProvider).valueOrNull ??
        MisclosureTolerance.defaults;
    return ListTile(
      key: const ValueKey('length-unit-tile'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      tileColor: colors.panel,
      leading: const Icon(Icons.square_foot),
      title: Text(l10n.settingsUnitTitle),
      subtitle: Text(lengthUnitName(l10n, tolerance.unit)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final unit = await showDialog<LengthUnit>(
          context: context,
          builder: (_) => LengthUnitDialog(initial: tolerance.unit),
        );
        if (unit == null || unit == tolerance.unit || !context.mounted) return;
        await _saveTolerance(context, ref, tolerance.copyWith(unit: unit));
      },
    );
  }
}

/// Metres / Feet choice with the "not converted" note; pops the unit.
class LengthUnitDialog extends StatefulWidget {
  final LengthUnit initial;

  const LengthUnitDialog({super.key, required this.initial});

  @override
  State<LengthUnitDialog> createState() => _LengthUnitDialogState();
}

class _LengthUnitDialogState extends State<LengthUnitDialog> {
  late LengthUnit _unit = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return AlertDialog(
      title: Text(l10n.settingsUnitTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioGroup<LengthUnit>(
              groupValue: _unit,
              onChanged: (value) {
                if (value != null) setState(() => _unit = value);
              },
              child: Column(
                children: [
                  for (final unit in LengthUnit.values)
                    RadioListTile<LengthUnit>(
                      value: unit,
                      title: Text(lengthUnitName(l10n, unit)),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsUnitNote,
              style: TextStyle(fontSize: 12.5, color: colors.subtext),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coreCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _unit),
          child: Text(l10n.coreSave),
        ),
      ],
    );
  }
}

class _MisclosureToleranceTile extends ConsumerWidget {
  const _MisclosureToleranceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final tolerance =
        ref.watch(misclosureToleranceProvider).valueOrNull ??
        MisclosureTolerance.defaults;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      tileColor: colors.panel,
      leading: const Icon(Icons.straighten),
      title: Text(l10n.settingsToleranceTitle),
      subtitle: Text(misclosureToleranceSummary(l10n, tolerance)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final updated = await showDialog<MisclosureTolerance>(
          context: context,
          builder: (_) => MisclosureToleranceDialog(initial: tolerance),
        );
        if (updated == null || updated == tolerance || !context.mounted) {
          return;
        }
        await _saveTolerance(context, ref, updated);
      },
    );
  }
}

/// Edits the misclosure tolerance rule in the entry unit of
/// `initial.unit` (mm for metres, ft for feet); pops the new rule (or null).
class MisclosureToleranceDialog extends StatefulWidget {
  final MisclosureTolerance initial;

  const MisclosureToleranceDialog({super.key, required this.initial});

  @override
  State<MisclosureToleranceDialog> createState() =>
      _MisclosureToleranceDialogState();
}

class _MisclosureToleranceDialogState extends State<MisclosureToleranceDialog> {
  late MisclosureToleranceMode _mode = widget.initial.mode;
  late final _fixedController = TextEditingController(
    text: formatToleranceValue(widget.initial.fixedEntry),
  );
  late final _coefficientController = TextEditingController(
    text: formatToleranceValue(widget.initial.coefficientEntry),
  );
  bool _showErrors = false;

  LengthUnit get _unit => widget.initial.unit;

  @override
  void dispose() {
    _fixedController.dispose();
    _coefficientController.dispose();
    super.dispose();
  }

  TextEditingController get _activeController =>
      _mode == MisclosureToleranceMode.fixed
      ? _fixedController
      : _coefficientController;

  void _submit() {
    final value = MisclosureTolerance.parseEntry(_activeController.text, _unit);
    if (value == null) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.pop(context, widget.initial.withEntry(_mode, value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final isFixed = _mode == MisclosureToleranceMode.fixed;
    final symbol = _unit.toleranceSymbol;
    final invalid =
        _showErrors &&
        MisclosureTolerance.parseEntry(_activeController.text, _unit) == null;
    return AlertDialog(
      title: Text(l10n.settingsToleranceTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<MisclosureToleranceMode>(
              segments: [
                ButtonSegment(
                  value: MisclosureToleranceMode.fixed,
                  label: Text(l10n.settingsToleranceModeFixed),
                ),
                ButtonSegment(
                  value: MisclosureToleranceMode.sqrtSetups,
                  label: Text(l10n.settingsToleranceModeSqrt),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() {
                _mode = selection.first;
                _showErrors = false;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              key: ValueKey(_mode),
              controller: _activeController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: isFixed
                    ? l10n.settingsToleranceFixedLabel(symbol)
                    : l10n.settingsToleranceCoefficientLabel(symbol),
                helperText: isFixed
                    ? l10n.settingsToleranceFixedHelper
                    : l10n.settingsToleranceSqrtHelper(symbol),
                helperMaxLines: 3,
                errorText: invalid
                    ? l10n.settingsToleranceInvalid(
                        formatToleranceValue(
                          MisclosureTolerance.minEntry(_unit),
                        ),
                        formatToleranceValue(
                          MisclosureTolerance.maxEntry(_unit),
                        ),
                        symbol,
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_showErrors) setState(() {});
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.settingsToleranceNote,
              style: TextStyle(fontSize: 12.5, color: colors.subtext),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coreCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.coreSave)),
      ],
    );
  }
}
