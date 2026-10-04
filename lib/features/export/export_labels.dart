import '../../l10n/l10n.dart';
import '../fieldbook/domain/fieldbook.dart';

/// Export-document labels for domain enums, in the export (app) language.
String exportReviewStatusLabel(
  AppLocalizations l10n,
  FieldBookReviewStatus status,
) => switch (status) {
  FieldBookReviewStatus.draft => l10n.exportReviewStatusDraft,
  FieldBookReviewStatus.reviewed => l10n.exportReviewStatusReviewed,
  FieldBookReviewStatus.needsCheck => l10n.exportReviewStatusNeedsCheck,
};

/// Measurement table headers: No. / Station / BS / FS / HI / RL / Remarks.
List<String> exportTableHeaders(AppLocalizations l10n) => [
  l10n.exportColumnNo,
  l10n.exportColumnStation,
  l10n.exportColumnBs,
  l10n.exportColumnFs,
  l10n.exportColumnHi,
  l10n.exportColumnRl,
  l10n.exportColumnRemarks,
];
