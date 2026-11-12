import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_events.dart';
import 'analytics_providers.dart';

/// Logs `pro_paywall_view` once, the first time [visible] is true (the Pro
/// entitlement is known to be absent), then just shows [child].
class ProPaywallImpression extends ConsumerStatefulWidget {
  /// An `AnalyticsValues.source*` value.
  final String source;
  final bool visible;
  final Widget child;

  const ProPaywallImpression({
    super.key,
    required this.source,
    required this.visible,
    required this.child,
  });

  @override
  ConsumerState<ProPaywallImpression> createState() =>
      _ProPaywallImpressionState();
}

class _ProPaywallImpressionState extends ConsumerState<ProPaywallImpression> {
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _maybeLog();
  }

  @override
  void didUpdateWidget(ProPaywallImpression oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLog();
  }

  void _maybeLog() {
    if (_logged || !widget.visible) return;
    _logged = true;
    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.proPaywallView,
      {AnalyticsParams.source: widget.source},
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
