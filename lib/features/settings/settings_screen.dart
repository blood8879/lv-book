import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../ads/ad_providers.dart';
import '../pro/pro_pdf_settings_screen.dart';
import '../purchase/purchase_controller.dart';
import '../purchase/purchase_providers.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final adsRemovedAsync = ref.watch(adsRemovedProvider);
    final purchaseController = ref.watch(purchaseControllerProvider);
    // Select on the message serial: the ChangeNotifier instance is the same
    // object for previous/next, so comparing `previous.message` never fires.
    // Ads-removed state is refreshed app-wide by the controller itself.
    ref.listen<(int, String?)>(
      purchaseControllerProvider.select(
        (controller) => (controller.messageSerial, controller.message),
      ),
      (previous, next) {
        final message = next.$2;
        if (message == null || next.$1 == previous?.$1) return;
        final isFailure =
            message.contains('실패') ||
            message.contains('오류') ||
            message.contains('취소') ||
            message.contains('못했습니다') ||
            message.contains('없습니다');
        if (isFailure) {
          AppSnackbar.error(context, message);
        } else {
          AppSnackbar.success(context, message);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          AppConstants.quickMemoFabClearance,
        ),
        children: [
          _ProPurchasePanel(
            adsRemovedAsync: adsRemovedAsync,
            purchaseController: purchaseController,
          ),
          const SizedBox(height: 12),
          const _SectionHeader(title: '구매 상태'),
          adsRemovedAsync.when(
            loading: () => const _StatusTile(
              icon: Icons.sync,
              title: '광고 제거 상태 확인 중',
              subtitle: '스토어와 로컬 권한을 확인합니다.',
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('광고 제거 상태를 불러오지 못했습니다'),
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
                title: const Text('광고 제거'),
                subtitle: Text(
                  adsRemoved
                      ? '구매 상태가 적용되어 광고가 표시되지 않습니다.'
                      : '스토어 상품 연결 후 일시구매로 모든 광고를 제거합니다.',
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
            title: const Text('구매 복원'),
            subtitle: Text(
              purchaseController.purchasePending
                  ? '스토어에서 구매 내역을 확인하는 중입니다.'
                  : '이미 구매한 Pro 권한을 복원합니다.',
            ),
            onTap: purchaseController.purchasePending
                ? null
                : purchaseController.restorePurchases,
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: '문서 설정'),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.line),
            ),
            tileColor: colors.panel,
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('제출용 PDF 설정'),
            subtitle: const Text('회사명, 템플릿, 워터마크, 서명을 설정합니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProPdfSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: '광고 노출 정책'),
          const _StatusTile(
            icon: Icons.view_stream_outlined,
            title: '배너 광고',
            subtitle: '화면 폭에 맞는 적응형 배너를 하단에 표시합니다.',
          ),
          const SizedBox(height: 8),
          const _StatusTile(
            icon: Icons.ios_share,
            title: '내보내기 광고',
            subtitle: '공유 완료 후 최대 하루 3회, 10분 간격으로만 표시합니다.',
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
                      isPro ? 'Pro 활성화됨' : '레벨 야장 Pro',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? '광고 없이 제출용 문서를 만들 수 있습니다.'
                          : price == null
                          ? '일회성 구매로 현장 기록 Pro 기능을 잠금 해제합니다.'
                          : '$price · 일회성 구매',
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
              _FeaturePill(label: '광고 제거', background: colors.darkSurface2),
              _FeaturePill(
                label: 'TBM/BM 사진 좌표',
                background: colors.darkSurface2,
              ),
              _FeaturePill(label: '일괄 내보내기', background: colors.darkSurface2),
              _FeaturePill(label: '요약 보고서', background: colors.darkSurface2),
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
                label: Text(isBusy ? '처리 중' : '레벨 야장 Pro 구매'),
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
