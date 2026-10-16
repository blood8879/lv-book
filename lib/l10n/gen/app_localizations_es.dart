// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get adsNativeAdLabel => 'Anuncio';

  @override
  String get adsPolicyBannerSubtitle =>
      'Se muestra abajo un banner adaptable al ancho de la pantalla.';

  @override
  String get adsPolicyBannerTitle => 'Anuncios de banner';

  @override
  String get adsPolicyExportSubtitle =>
      'Solo se muestran al terminar de compartir, como máximo 3 veces al día y con al menos 10 minutos de separación.';

  @override
  String get adsPolicyExportTitle => 'Anuncios al exportar';

  @override
  String get adsPolicySection => 'Política de anuncios';

  @override
  String get backupErrorBenchmarkCorrupted => 'Los datos de BM están dañados.';

  @override
  String get backupErrorCorrupted => 'Los datos de la copia están dañados.';

  @override
  String get backupErrorFieldBookCorrupted =>
      'Los datos de la libreta están dañados.';

  @override
  String get backupErrorInvalidFormat =>
      'El formato del archivo de copia no es válido.';

  @override
  String get backupErrorMeasurementCorrupted =>
      'Los datos de los puntos están dañados.';

  @override
  String get backupErrorPhotoCorrupted =>
      'Los datos de las fotos de la copia están dañados.';

  @override
  String get backupErrorProjectNotFound => 'No se encontró el proyecto.';

  @override
  String get backupErrorUnsupported =>
      'Este archivo de copia no es compatible.';

  @override
  String benchmarkAccuracy(String accuracy) {
    return 'Precisión $accuracy m';
  }

  @override
  String get benchmarkAddDialogTitle => 'Agregar BM';

  @override
  String get benchmarkCopyCoordinateButton => 'Copiar coordenadas';

  @override
  String benchmarkCopyCoordinateText(String latitude, String longitude) {
    return 'Lat $latitude, Lon $longitude';
  }

  @override
  String benchmarkDeleteConfirm(String name, String elevation) {
    return '¿Eliminar \"$name\" (cota: $elevation)?';
  }

  @override
  String get benchmarkDeleteDialogTitle => 'Eliminar BM';

  @override
  String get benchmarkDescriptionLabel => 'Descripción (opcional)';

  @override
  String get benchmarkEditDialogTitle => 'Editar BM';

  @override
  String get benchmarkElevationHint => 'p. ej. 100.000';

  @override
  String benchmarkElevationInvalidError(String unit) {
    return 'Ingrese la cota como número ($unit)';
  }

  @override
  String benchmarkElevationLabel(String unit) {
    return 'Cota ($unit) *';
  }

  @override
  String benchmarkElevationLine(String elevation, String unit) {
    return 'Cota $elevation $unit';
  }

  @override
  String get benchmarkEmptyMessage =>
      'Agregue con el botón + un BM/TBM como referencia de cota\ny cárguelo como cota inicial al crear una libreta.';

  @override
  String get benchmarkEmptyTitle => 'Agregue un BM (banco de nivel)';

  @override
  String get benchmarkKindLabel => 'Tipo';

  @override
  String benchmarkKindLine(String kind) {
    return 'Tipo: $kind';
  }

  @override
  String get benchmarkLocationHintLabel => 'Referencia de ubicación';

  @override
  String benchmarkLocationLine(String hint) {
    return 'Ubicación: $hint';
  }

  @override
  String get benchmarkLocationPermissionDenied =>
      'Se denegó el permiso de ubicación.';

  @override
  String get benchmarkLocationPermissionDeniedForever =>
      'El permiso de ubicación se denegó de forma permanente. Actívelo en los ajustes de la app.';

  @override
  String get benchmarkLocationServiceOff =>
      'Los servicios de ubicación están desactivados en este dispositivo.';

  @override
  String get benchmarkMapOpenError =>
      'No se pudo abrir una app de mapas. Copie las coordenadas.';

  @override
  String get benchmarkNameHint => 'p. ej. BM.1';

  @override
  String get benchmarkNameLabel => 'Nombre del BM *';

  @override
  String get benchmarkNameRequiredError => 'Ingrese el nombre del BM';

  @override
  String get benchmarkNoSavedCoordinate => 'No hay coordenadas guardadas.';

  @override
  String get benchmarkNoSavedPhoto => 'No hay foto guardada.';

  @override
  String get benchmarkOpenMapButton => 'Abrir mapa';

  @override
  String get benchmarkPhotoFileMissing =>
      'No se encontró el archivo de la foto.';

  @override
  String get benchmarkPhotoNeedsSavedBm =>
      'Solo se pueden agregar fotos a un BM guardado.';

  @override
  String get benchmarkPhotoSaveError => 'No se pudo guardar la foto.';

  @override
  String get benchmarkPhotoSaved => 'Foto guardada';

  @override
  String get benchmarkPickPhotoButton => 'Elegir foto';

  @override
  String get benchmarkProLocationPromo =>
      'Con Pro puede guardar fotos y coordenadas de TBM/BM.';

  @override
  String get benchmarkProLocationSaved => 'Ubicación Pro guardada';

  @override
  String get benchmarkProLocationTitle => 'Ubicación Pro';

  @override
  String get benchmarkProRequired => 'Disponible al comprar Lv Book Pro.';

  @override
  String get benchmarkProtectionLabel => 'Notas de protección/revisión';

  @override
  String benchmarkProtectionLine(String note) {
    return 'Protección: $note';
  }

  @override
  String get benchmarkRecheckNoVerifiedDate =>
      'Sin fecha de última verificación. Requiere verificación';

  @override
  String get benchmarkRecheckOutOfService =>
      'Este BM está fuera de servicio. No se puede usar como BM inicial de una libreta nueva.';

  @override
  String get benchmarkRecheckPossiblyDamaged =>
      'Este BM podría estar dañado. Verifíquelo en campo antes de usarlo.';

  @override
  String benchmarkRecheckStale(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días desde la última verificación. Requiere verificación',
      one: '1 día desde la última verificación. Requiere verificación',
    );
    return '$_temp0';
  }

  @override
  String get benchmarkRemovePhotoButton => 'Quitar foto';

  @override
  String get benchmarkSaveCurrentCoordinate => 'Guardar coordenadas actuales';

  @override
  String get benchmarkSavingCoordinate => 'Guardando coordenadas';

  @override
  String get benchmarkStatusLabel => 'Estado';

  @override
  String get benchmarkStatusOutOfService => 'Fuera de servicio';

  @override
  String get benchmarkStatusPossiblyDamaged => 'Posible daño';

  @override
  String get benchmarkStatusUsable => 'Utilizable';

  @override
  String get benchmarkTakePhotoButton => 'Tomar foto';

  @override
  String get coreAdd => 'Agregar';

  @override
  String get coreAppName => 'Lv Book';

  @override
  String get coreAppProName => 'Lv Book Pro';

  @override
  String get coreCancel => 'Cancelar';

  @override
  String get coreClose => 'Cerrar';

  @override
  String get coreConfirm => 'Aceptar';

  @override
  String get coreDelete => 'Eliminar';

  @override
  String get coreEdit => 'Editar';

  @override
  String coreErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get coreFileNotUtf8 =>
      'Solo se admiten archivos UTF-8. En Excel, guarde el archivo de nuevo como \"CSV UTF-8 (delimitado por comas)\".';

  @override
  String get coreJudgementCheckRequired => 'Requiere revisión';

  @override
  String get coreJudgementOk => 'OK';

  @override
  String get coreJudgementWithinTolerance => 'Dentro de tolerancia';

  @override
  String get coreProcessing => 'Procesando…';

  @override
  String get coreRetry => 'Reintentar';

  @override
  String get coreSave => 'Guardar';

  @override
  String get coreSaved => 'Guardado';

  @override
  String coreSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
      zero: 'Ninguno seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get exportBulkDeselectAll => 'Ninguna';

  @override
  String exportBulkError(String error) {
    return 'La exportación múltiple no se completó: $error';
  }

  @override
  String get exportBulkFormatBoth => 'Ambos';

  @override
  String get exportBulkFormatXlsx => 'Excel';

  @override
  String get exportBulkManifestSubtitle =>
      'Enumera las libretas seleccionadas, los archivos generados y el número de puntos.';

  @override
  String get exportBulkManifestTitle =>
      'Incluir manifiesto del paquete de entrega';

  @override
  String get exportBulkNothingToExport =>
      'Ninguna libreta seleccionada tiene datos para exportar';

  @override
  String get exportBulkProOnlyBody =>
      'Comparta varias libretas en PDF/CSV/Excel a la vez.';

  @override
  String get exportBulkProOnlyTitle => 'Función Pro';

  @override
  String get exportBulkProRequired =>
      'Disponible con Lv Book Pro (pago único).';

  @override
  String get exportBulkSelectAll => 'Todas';

  @override
  String exportBulkShareButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compartir $count libretas',
      one: 'Compartir 1 libreta',
    );
    return '$_temp0';
  }

  @override
  String exportBulkShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos compartidos',
      one: '1 archivo compartido',
    );
    return '$_temp0';
  }

  @override
  String get exportBulkSummarySubtitle =>
      'Reúne en un archivo el BM, tramo, error de cierre y resultado de cada libreta.';

  @override
  String get exportBulkSummaryTitle =>
      'Incluir CSV resumen de revisión/entrega';

  @override
  String get exportBulkTitle => 'Exportación múltiple';

  @override
  String get exportCheckAllowed => 'Tolerancia';

  @override
  String get exportCheckDifference => 'Diferencia';

  @override
  String get exportCheckFinalRl => 'Cota final';

  @override
  String get exportCheckMisclosure => 'Error de cierre';

  @override
  String get exportCheckMisclosureUnavailable => 'n/d (sin cota de cierre)';

  @override
  String get exportCheckResult => 'Resultado';

  @override
  String get exportCheckRiseFallDifference => 'ΣAsc − ΣDesc';

  @override
  String get exportCheckRlDifference => 'Final - Inicial';

  @override
  String get exportCheckStartRl => 'Cota inicial';

  @override
  String get exportCheckSumBs => 'ΣVAt';

  @override
  String get exportCheckSumFall => 'ΣDesc';

  @override
  String get exportCheckSumFs => 'ΣVAd';

  @override
  String get exportCheckSumRise => 'ΣAsc';

  @override
  String get exportCheckTitle => 'Comprobación aritmética';

  @override
  String get exportCheckTitleWithClosure =>
      'Comprobación aritmética y error de cierre';

  @override
  String exportCheckValue(String label, String value) {
    return '$label = $value';
  }

  @override
  String exportClosingLoopName(String name) {
    return '$name (circuito)';
  }

  @override
  String get exportColumnBs => 'VAt';

  @override
  String get exportColumnCutFill => 'Corte(+)/Relleno(−)';

  @override
  String get exportColumnDesign => 'Cota de proyecto';

  @override
  String get exportColumnFall => 'Descenso';

  @override
  String get exportColumnFs => 'VAd';

  @override
  String get exportColumnHi => 'AI';

  @override
  String get exportColumnIs => 'VI';

  @override
  String get exportColumnNo => 'N.º';

  @override
  String get exportColumnRemarks => 'Observaciones';

  @override
  String get exportColumnRise => 'Ascenso';

  @override
  String get exportColumnRl => 'Cota';

  @override
  String get exportColumnStation => 'Punto';

  @override
  String get exportColumnTarget => 'Lectura objetivo';

  @override
  String get exportCompanyNotSet => 'Empresa sin definir';

  @override
  String exportCsvError(String error) {
    return 'No se pudo crear el CSV: $error';
  }

  @override
  String get exportCutLetter => 'C';

  @override
  String get exportDocTitle => 'Libreta de nivelación geométrica';

  @override
  String exportDocTitleWithTemplate(String template) {
    return 'Libreta de nivelación geométrica · $template';
  }

  @override
  String get exportFieldAuthor => 'Elaborado por';

  @override
  String get exportFieldBmElevation => 'Cota del BM';

  @override
  String get exportFieldChecker => 'Revisor';

  @override
  String get exportFieldClosingBm => 'BM de cierre';

  @override
  String get exportFieldClosingRl => 'Cota de cierre';

  @override
  String get exportFieldCompany => 'Empresa';

  @override
  String get exportFieldDate => 'Fecha';

  @override
  String get exportFieldInstrument => 'Instrumento';

  @override
  String get exportFieldJobNumber => 'N.º de trabajo';

  @override
  String get exportFieldMemo => 'Nota';

  @override
  String get exportFieldProject => 'Proyecto';

  @override
  String get exportFieldReductionMethod => 'Método de cálculo';

  @override
  String get exportFieldReviewDate => 'Fecha de revisión';

  @override
  String get exportFieldReviewMemo => 'Nota de revisión';

  @override
  String get exportFieldReviewStatus => 'Estado de revisión';

  @override
  String get exportFieldSection => 'Tramo';

  @override
  String get exportFieldStartBm => 'BM inicial';

  @override
  String get exportFieldSurveyor => 'Topógrafo';

  @override
  String get exportFieldTitle => 'Libreta';

  @override
  String get exportFieldUnit => 'Unidad';

  @override
  String get exportFieldWeather => 'Clima';

  @override
  String get exportFillLetter => 'R';

  @override
  String exportImportDateMissing(String date) {
    return 'El CSV no tiene fecha; se usó $date.';
  }

  @override
  String exportImportDateUnrecognized(String value, String date) {
    return 'No se pudo leer la fecha \"$value\"; se usó $date.';
  }

  @override
  String get exportImportDefaultTitle => 'Libreta importada';

  @override
  String get exportImportHeaderNotFound =>
      'No se encontró el encabezado de la tabla de lecturas.';

  @override
  String exportImportInvalidNumber(int row, String column) {
    return 'Fila $row: $column no es un número válido.';
  }

  @override
  String exportImportUnitMismatch(String fileUnit, String appUnit) {
    return 'El archivo está en $fileUnit pero la app usa $appUnit. Los números se importaron sin cambios.';
  }

  @override
  String get exportImportUtf8Only =>
      'Solo se admite CSV en UTF-8. Algunos caracteres están dañados, así que no se puede importar el archivo. En Excel, guárdelo de nuevo como \"CSV UTF-8 (delimitado por comas)\".';

  @override
  String exportLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String exportManifestFieldBookLine(String title, int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos',
      one: '1 punto',
    );
    return '- $title: $_temp0, estado de revisión $status';
  }

  @override
  String exportManifestFileCount(int count) {
    return 'Archivos: $count';
  }

  @override
  String get exportManifestIncludedFiles => 'Archivos incluidos';

  @override
  String exportManifestSite(String name) {
    return 'Obra: $name';
  }

  @override
  String get exportManifestSiteNotSet => 'Obra sin nombre';

  @override
  String get exportManifestTitle => 'Paquete de entrega de Lv Book';

  @override
  String get exportPackageNoFieldBooks => 'No hay libretas para empaquetar.';

  @override
  String get exportPackageNoFiles => 'No hay archivos para empaquetar.';

  @override
  String get exportPackageZipError =>
      'No se pudo crear el ZIP del paquete de entrega.';

  @override
  String exportPdfError(String error) {
    return 'No se pudo crear el PDF: $error';
  }

  @override
  String get exportReductionHi => 'Altura instrumental';

  @override
  String get exportReductionRiseFall => 'Ascensos y descensos';

  @override
  String get exportReviewStatusDraft => 'Borrador';

  @override
  String get exportReviewStatusNeedsCheck => 'Por revisar';

  @override
  String get exportReviewStatusReviewed => 'Revisado';

  @override
  String get exportScreenTitle => 'Exportar';

  @override
  String get exportShareCsvTooltip => 'Compartir CSV';

  @override
  String get exportSharePdfTooltip => 'Compartir PDF';

  @override
  String get exportShareXlsxTooltip => 'Compartir Excel (.xlsx)';

  @override
  String get exportSignatureApproved => 'Aprobó';

  @override
  String get exportSignatureChecked => 'Revisó';

  @override
  String get exportSignaturePrepared => 'Elaboró';

  @override
  String get exportSummaryFileSuffix => 'resumen';

  @override
  String get exportSummaryNoSelection =>
      'Seleccione las libretas que desea resumir.';

  @override
  String exportXlsxError(String error) {
    return 'No se pudo crear el archivo de Excel: $error';
  }

  @override
  String get exportXlsxSheetName => 'Libreta';

  @override
  String get fieldbookAddTenRowsTooltip => 'Agregar 10 filas';

  @override
  String fieldbookArithmeticCheckResult(String result) {
    return 'Comprobación aritmética: $result';
  }

  @override
  String get fieldbookBackupPasteHint =>
      'O pegue el contenido de un lvbook_backup.json compartido.';

  @override
  String get fieldbookBackupRestoredMessage =>
      'Copia restaurada como un proyecto nuevo.';

  @override
  String get fieldbookBmNameHint => 'p. ej. BM.1';

  @override
  String get fieldbookBmNameLabel => 'Nombre del BM (opcional)';

  @override
  String get fieldbookBulkExportButton => 'Exportar varias';

  @override
  String get fieldbookCheckArithmetic => 'Comprobación aritmética';

  @override
  String get fieldbookCheckEmptyRows => 'Filas vacías';

  @override
  String get fieldbookCheckFirstBs => 'Primera VAt';

  @override
  String get fieldbookCheckLastFs => 'Última VAd';

  @override
  String get fieldbookCheckRiseFall => 'Comprobación Asc/Desc';

  @override
  String get fieldbookCheckStationRows => 'Filas de puntos';

  @override
  String get fieldbookCheckTolerance => 'Tolerancia';

  @override
  String get fieldbookCheckTpComplete => 'TP completos';

  @override
  String get fieldbookCheckerLabel => 'Revisor';

  @override
  String get fieldbookChooseBackupFile => 'Elegir archivo de copia (.json)';

  @override
  String get fieldbookChooseCsvFile => 'Elegir archivo CSV (.csv)';

  @override
  String get fieldbookClosingApply => 'Aplicar';

  @override
  String get fieldbookClosingBmLabel => 'BM de cierre';

  @override
  String fieldbookClosingElevationLabel(String unit) {
    return 'Cota de cierre ($unit)';
  }

  @override
  String get fieldbookClosingInvalid => 'Ingrese una cota válida.';

  @override
  String get fieldbookClosingLabel => 'Cota de cierre';

  @override
  String get fieldbookClosingLoop => 'BM inicial (circuito cerrado)';

  @override
  String get fieldbookClosingLoopShort => 'Circuito';

  @override
  String get fieldbookClosingManual => 'Cota manual';

  @override
  String get fieldbookClosingManualShort => 'Manual';

  @override
  String get fieldbookClosingNoBm => 'No hay BM utilizables en este proyecto.';

  @override
  String get fieldbookClosingNone => 'Ninguna';

  @override
  String get fieldbookClosingNotSet => 'Sin definir';

  @override
  String get fieldbookClosingOtherBm => 'Otro BM';

  @override
  String get fieldbookClosingSheetHelp =>
      'Error de cierre = cota final − cota de cierre. Sin referencia de cierre solo se muestra la comprobación aritmética.';

  @override
  String get fieldbookClosingSheetTitle => 'Referencia de cierre';

  @override
  String fieldbookClosingSummary(String name, String rl) {
    return '$name · $rl';
  }

  @override
  String get fieldbookColumnBs => 'VAt';

  @override
  String get fieldbookColumnCutFill => 'Corte(+)/Rell.(−)';

  @override
  String get fieldbookColumnDesign => 'Cota proy.';

  @override
  String get fieldbookColumnFs => 'VAd';

  @override
  String get fieldbookColumnHi => 'AI';

  @override
  String get fieldbookColumnNo => 'Pto.';

  @override
  String get fieldbookColumnRiseFall => 'Asc/Desc';

  @override
  String get fieldbookColumnRl => 'Cota';

  @override
  String get fieldbookColumnTarget => 'Lect. obj.';

  @override
  String get fieldbookContinueButton => 'Continuar';

  @override
  String fieldbookCopyName(String name) {
    return '$name (copia)';
  }

  @override
  String get fieldbookCreateButton => 'Crear';

  @override
  String fieldbookCsvImportError(String error) {
    return 'No se pudo importar el CSV: $error';
  }

  @override
  String get fieldbookCsvImported => 'CSV importado';

  @override
  String fieldbookCsvImportedWithWarnings(String warnings) {
    return 'CSV importado. $warnings';
  }

  @override
  String get fieldbookCsvPasteHint => 'O pegue un CSV exportado desde Lv Book.';

  @override
  String get fieldbookCutLetter => 'C';

  @override
  String fieldbookDeleteConfirm(String title) {
    return '¿Eliminar la libreta \"$title\"?';
  }

  @override
  String fieldbookDeleteRowConfirm(int row) {
    return '¿Eliminar la fila $row?';
  }

  @override
  String get fieldbookDeleteRowTitle => 'Eliminar fila';

  @override
  String get fieldbookDeleteTitle => 'Eliminar libreta';

  @override
  String get fieldbookDesignToggleHelp =>
      'Agrega una columna de cota de proyecto. Corte/relleno = cota − proyecto: C (corte) si el terreno está por encima del proyecto, R (relleno) si está por debajo. Lect. obj. = AI − proyecto: la lectura de mira para replantear.';

  @override
  String get fieldbookDesignToggleLabel => 'Cota de proyecto y corte/relleno';

  @override
  String fieldbookDuplicateError(String error) {
    return 'No se pudo duplicar la libreta: $error';
  }

  @override
  String get fieldbookDuplicateStructure => 'Duplicar estructura';

  @override
  String get fieldbookDuplicatedMessage => 'Estructura de la libreta duplicada';

  @override
  String get fieldbookEditStationTitle => 'Editar punto';

  @override
  String get fieldbookEmptyMessage =>
      'Toque + para crear una libreta\no importe registros existentes desde CSV.';

  @override
  String get fieldbookEmptyTitle => 'Cree su primera libreta';

  @override
  String get fieldbookEnterManually => 'Ingresar a mano';

  @override
  String get fieldbookExportCheckTitle => 'Revisar antes de exportar';

  @override
  String get fieldbookExportTooltip => 'Exportar';

  @override
  String get fieldbookFabLabel => 'Libreta';

  @override
  String get fieldbookFillLetter => 'R';

  @override
  String get fieldbookImportButton => 'Importar';

  @override
  String get fieldbookImportCsv => 'Importar CSV';

  @override
  String get fieldbookInstrumentLabel => 'Instrumento';

  @override
  String get fieldbookIssueArithmeticMismatch =>
      'La comprobación aritmética no cuadra: revise las cotas.';

  @override
  String get fieldbookIssueEmptyRows => 'Elimine las filas sin lecturas.';

  @override
  String get fieldbookIssueExceedsTolerance =>
      'Supera la tolerancia: revise las lecturas.';

  @override
  String get fieldbookIssueFirstBsMissing =>
      'La primera fila necesita una vista atrás (VAt).';

  @override
  String get fieldbookIssueLastFsMissing =>
      'La última fila necesita una vista adelante (VAd).';

  @override
  String get fieldbookIssueNoStationRows =>
      'Agregue al menos una fila de punto.';

  @override
  String get fieldbookIssueRiseFallMismatch =>
      'ΣAsc − ΣDesc no coincide con ΣVAt − ΣVAd. Revise las lecturas.';

  @override
  String get fieldbookIssueTpIncomplete => 'Las filas TP necesitan VAt y VAd.';

  @override
  String get fieldbookJobNumberLabel => 'N.º de trabajo';

  @override
  String fieldbookMisclosureCheckResult(String result) {
    return 'Error de cierre: $result';
  }

  @override
  String get fieldbookNewTitle => 'Nueva libreta';

  @override
  String get fieldbookNoDataToExport => 'No hay datos para exportar';

  @override
  String get fieldbookNoSearchResults => 'Sin resultados';

  @override
  String get fieldbookReductionHelp =>
      'Ascensos y descensos muestra el ascenso o descenso de cada lectura y agrega la comprobación ΣAsc − ΣDesc. Las cotas no cambian.';

  @override
  String get fieldbookReductionHi => 'AI';

  @override
  String get fieldbookReductionMethodLabel => 'Método de cálculo';

  @override
  String get fieldbookReductionRiseFall => 'Asc./Desc.';

  @override
  String fieldbookRestoreBackupError(String error) {
    return 'No se pudo restaurar la copia: $error';
  }

  @override
  String get fieldbookRestoreBackupJson => 'Restaurar copia JSON';

  @override
  String get fieldbookRestoreButton => 'Restaurar';

  @override
  String get fieldbookReviewMemoHint => 'p. ej. Confirmado por el supervisor';

  @override
  String get fieldbookReviewMemoLabel => 'Notas de revisión';

  @override
  String get fieldbookReviewPanelTitle => 'Revisión';

  @override
  String get fieldbookReviewSaveButton => 'Guardar revisión';

  @override
  String get fieldbookReviewSavedMessage => 'Revisión guardada';

  @override
  String get fieldbookReviewStatusLabel => 'Estado de revisión';

  @override
  String get fieldbookReviewTodayButton => 'Usar hoy como fecha de revisión';

  @override
  String fieldbookReviewedOn(String date) {
    return 'Revisado el $date';
  }

  @override
  String get fieldbookRowActionsTooltip => 'Acciones de fila';

  @override
  String get fieldbookRowDuplicate => 'Duplicar fila';

  @override
  String get fieldbookRowInsertBelow => 'Insertar fila debajo';

  @override
  String get fieldbookRowSetManualTp => 'Marcar como TP manual';

  @override
  String get fieldbookRowUnsetManualTp => 'Quitar TP manual';

  @override
  String get fieldbookSaveStatusAutosaved => 'Guardado automático';

  @override
  String get fieldbookSaveStatusError => 'No guardado';

  @override
  String get fieldbookSaveStatusPending => 'Guardado automático pendiente';

  @override
  String get fieldbookSaveStatusSaved => 'Guardado';

  @override
  String get fieldbookSavedMessage => 'Guardado';

  @override
  String get fieldbookSearchHint => 'Título, tramo, topógrafo, fecha';

  @override
  String get fieldbookSearchLabel => 'Buscar libretas';

  @override
  String get fieldbookSelectBm => 'Elegir BM';

  @override
  String get fieldbookShareBackup => 'Compartir copia del proyecto';

  @override
  String fieldbookShareBackupError(String error) {
    return 'No se pudo compartir la copia: $error';
  }

  @override
  String get fieldbookSiteDetailsSummary => 'Topógrafo, instrumento, clima…';

  @override
  String get fieldbookSiteDetailsTitle => 'Datos de campo';

  @override
  String get fieldbookStartBmLabel => 'BM inicial';

  @override
  String get fieldbookStartElevationHint => 'p. ej. 100.000';

  @override
  String fieldbookStartElevationLabel(String unit) {
    return 'Cota inicial ($unit) *';
  }

  @override
  String get fieldbookStartRlLabel => 'Cota inicial';

  @override
  String fieldbookStationHelper(int row) {
    return 'Déjelo vacío para mostrar el número de fila ($row)';
  }

  @override
  String get fieldbookStationHint => 'p. ej. No.1, BM.1, TP.1';

  @override
  String get fieldbookStationLabel => 'Punto';

  @override
  String get fieldbookStatusDraft => 'Borrador';

  @override
  String get fieldbookStatusNeedsCheck => 'Por revisar';

  @override
  String get fieldbookStatusReviewed => 'Revisado';

  @override
  String fieldbookSummaryAllowed(String value) {
    return 'Tolerancia $value';
  }

  @override
  String get fieldbookSummaryArithmetic => 'Comp. arit.';

  @override
  String get fieldbookSummaryDiff => 'Dif.';

  @override
  String get fieldbookSummaryFinal => 'Cota final';

  @override
  String get fieldbookSummaryMisclosure => 'Error de cierre';

  @override
  String get fieldbookSummaryNoClosing => 'Sin cota de cierre';

  @override
  String fieldbookSummaryRiseMinusFall(String value) {
    return 'A − D $value';
  }

  @override
  String get fieldbookSummaryStart => 'Cota inicial';

  @override
  String get fieldbookSummarySumBs => 'ΣVAt';

  @override
  String fieldbookSummarySumFall(String value) {
    return 'ΣDesc $value';
  }

  @override
  String get fieldbookSummarySumFs => 'ΣVAd';

  @override
  String fieldbookSummarySumRise(String value) {
    return 'ΣAsc $value';
  }

  @override
  String get fieldbookSurveyorLabel => 'Topógrafo';

  @override
  String fieldbookSurveyorSubtitle(String name) {
    return 'Topógrafo: $name';
  }

  @override
  String get fieldbookTitleHint => 'Título de la libreta';

  @override
  String get fieldbookTitleLabel => 'Título de la libreta *';

  @override
  String get fieldbookToleranceCheckTitle => 'Revise la tolerancia';

  @override
  String get fieldbookWeatherLabel => 'Clima';

  @override
  String get fieldbookWorkSectionLabel => 'Tramo';

  @override
  String pegTestAdjustInstruction(String reading, String unit) {
    return 'Ajuste el retículo hasta que la mira en B marque $reading $unit.';
  }

  @override
  String get pegTestAdjustmentRequired => 'Requiere ajuste';

  @override
  String get pegTestAngle => 'Ángulo de la visual';

  @override
  String get pegTestCollimationError => 'Error de colimación en A–B';

  @override
  String get pegTestCopied => 'Resultado copiado';

  @override
  String get pegTestCopyResult => 'Copiar resultado';

  @override
  String get pegTestCorrectReading => 'Lectura correcta en B';

  @override
  String get pegTestDeleteConfirm =>
      'Se eliminará la prueba de dos estacas guardada. Esta acción no se puede deshacer.';

  @override
  String get pegTestDeleteTitle => '¿Eliminar este registro?';

  @override
  String get pegTestDeleted => 'Registro eliminado';

  @override
  String get pegTestDistanceInvalid => 'Ingrese una distancia mayor que 0.';

  @override
  String pegTestDistanceLabel(String unit) {
    return 'Distancia A–B ($unit)';
  }

  @override
  String pegTestErrorPer100(String unit) {
    return 'Error cada 100 $unit';
  }

  @override
  String get pegTestHistoryEmptyMessage =>
      'Guarde el resultado de una prueba de dos estacas para tener un registro fechado de la revisión del instrumento.';

  @override
  String get pegTestHistoryEmptyTitle => 'Aún no hay pruebas guardadas';

  @override
  String get pegTestHistoryTitle => 'Pruebas de dos estacas guardadas';

  @override
  String get pegTestHistoryTooltip => 'Pruebas guardadas';

  @override
  String get pegTestHowToStep1 =>
      'Coloque las estacas A y B en terreno firme y estacione el nivel exactamente en el punto medio.';

  @override
  String get pegTestHowToStep2 =>
      'Lea la mira en A y luego en B (estación 1). Con visuales iguales el error de colimación se anula.';

  @override
  String get pegTestHowToStep3 =>
      'Lleve el nivel cerca de A, justo detrás o al lado, y nivélelo de nuevo.';

  @override
  String get pegTestHowToStep4 =>
      'Lea A y luego B otra vez (estación 2) e ingrese la distancia entre estacas.';

  @override
  String get pegTestHowToTitle => 'Cómo hacer la prueba';

  @override
  String get pegTestInclinedDown => 'La visual apunta hacia abajo';

  @override
  String get pegTestInclinedUp => 'La visual apunta hacia arriba';

  @override
  String get pegTestInstrumentLabel => 'Instrumento';

  @override
  String get pegTestNoInstrument => 'Instrumento sin indicar';

  @override
  String get pegTestNoteLabel => 'Nota';

  @override
  String get pegTestObserverLabel => 'Observador';

  @override
  String pegTestPdfError(String error) {
    return 'No se pudo crear el PDF: $error';
  }

  @override
  String pegTestReadingALabel(String unit) {
    return 'Mira en A ($unit)';
  }

  @override
  String pegTestReadingBLabel(String unit) {
    return 'Mira en B ($unit)';
  }

  @override
  String get pegTestReadingsTitle => 'Lecturas';

  @override
  String get pegTestRecordDetailsHint =>
      'Instrumento, observador y nota del registro guardado';

  @override
  String get pegTestRecordDetailsTitle => 'Datos del registro (opcional)';

  @override
  String get pegTestRecordSaved => 'Registro guardado';

  @override
  String get pegTestRecordTitle => 'Registro de prueba de dos estacas';

  @override
  String get pegTestResultEmpty =>
      'Ingrese las cuatro lecturas y la distancia entre estacas para ver el resultado.';

  @override
  String get pegTestResultTitle => 'Resultado';

  @override
  String get pegTestSaveRecord => 'Guardar registro';

  @override
  String get pegTestSetup1Title => 'Estación 1 · en el punto medio entre A y B';

  @override
  String get pegTestSetup2Title => 'Estación 2 · cerca de A';

  @override
  String get pegTestSharePdfTooltip => 'Compartir PDF';

  @override
  String get pegTestSubtitle => 'Comprobación de colimación del nivel';

  @override
  String pegTestSummaryLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get pegTestSummaryResult => 'Resultado';

  @override
  String pegTestSummarySetup1(String a, String b) {
    return 'Estación 1 (punto medio): A $a, B $b';
  }

  @override
  String pegTestSummarySetup2(String a, String b) {
    return 'Estación 2 (cerca de A): A $a, B $b';
  }

  @override
  String get pegTestTitle => 'Prueba de dos estacas';

  @override
  String get pegTestToleranceDialogTitle => 'Tolerancia de dos estacas';

  @override
  String get pegTestToleranceEditTooltip => 'Editar tolerancia';

  @override
  String pegTestToleranceFieldLabel(String unit) {
    return 'Error admisible en A–B ($unit)';
  }

  @override
  String get pegTestToleranceLabel => 'Tolerancia';

  @override
  String pegTestToleranceValue(String value, String unit) {
    return '±$value $unit en A–B';
  }

  @override
  String get pegTestTrueDifference => 'Diferencia real (A − B)';

  @override
  String get proActiveSubtitle => 'Cree documentos de entrega sin anuncios.';

  @override
  String get proActiveTitle => 'Pro activado';

  @override
  String get proBuyButton => 'Comprar Lv Book Pro';

  @override
  String get proFeatureBenchmarkPhotoLocation => 'Foto y ubicación de TBM/BM';

  @override
  String get proFeatureBulkExport => 'Exportación múltiple';

  @override
  String get proFeatureNoAds => 'Sin anuncios';

  @override
  String get proFeatureSummaryReport => 'Informe resumen';

  @override
  String get proFileNameSiteDateTitle => 'Obra_Fecha_Libreta';

  @override
  String get proFileNameSiteSectionDateTitle => 'Obra_Tramo_Fecha_Libreta';

  @override
  String get proFileNameTitleOnly => 'Nombre de la libreta';

  @override
  String get proInspectionWatermarkDefault => 'Inspección';

  @override
  String get proPdfAuthorHint => 'p. ej. Ana López';

  @override
  String get proPdfAuthorLabel => 'Autor';

  @override
  String get proPdfCompanyHint => 'p. ej. Topografía Andina S.A.';

  @override
  String get proPdfCompanyLabel => 'Nombre de la empresa';

  @override
  String get proPdfExportHistory => 'Historial de exportación';

  @override
  String get proPdfExportHistoryClearAll => 'Borrar todo';

  @override
  String get proPdfExportHistoryEmpty => 'No hay historial de exportación.';

  @override
  String get proPdfFileNamePreviewLabel => 'Vista previa del nombre de archivo';

  @override
  String get proPdfFileNameRuleLabel => 'Regla de nombre de archivo';

  @override
  String get proPdfFooterNoteHint =>
      'p. ej. Confirmado por el residente de obra';

  @override
  String get proPdfFooterNoteLabel => 'Nota al pie';

  @override
  String proPdfLoadError(String error) {
    return 'No se pudieron cargar los ajustes: $error';
  }

  @override
  String get proPdfPresetAdd => 'Agregar perfil';

  @override
  String get proPdfPresetDeleteTooltip => 'Eliminar perfil';

  @override
  String get proPdfPresetDeletedMessage => 'Perfil eliminado';

  @override
  String get proPdfPresetLabel => 'Perfil de documento';

  @override
  String get proPdfPresetNameLabel => 'Nombre del perfil';

  @override
  String get proPdfPresetNewName => 'Perfil nuevo';

  @override
  String get proPdfPresetRename => 'Cambiar nombre del perfil';

  @override
  String get proPdfPreviewSampleSite => 'Obra Ribera';

  @override
  String get proPdfPreviewSampleTitle => 'Libreta tramo A';

  @override
  String get proPdfSavedMessage => 'Ajustes PDF Pro guardados';

  @override
  String get proPdfSettingsTitle => 'Ajustes PDF Pro';

  @override
  String get proPdfShowJudgementSubtitle =>
      'Incluye Dentro de tolerancia / Requiere revisión en el PDF y el CSV.';

  @override
  String get proPdfShowJudgementTitle =>
      'Mostrar resultado de la comprobación aritmética';

  @override
  String get proPdfSignatureDescription =>
      'Registre una firma manuscrita para la casilla \'Elaborado por\' del PDF.';

  @override
  String get proPdfSignatureDisplayError => 'No se puede mostrar la firma';

  @override
  String get proPdfSignatureEmpty => 'No hay firma registrada';

  @override
  String get proPdfSignatureLinesSubtitle =>
      'Agrega casillas Elaboró / Revisó / Aprobó al pie del PDF de entrega.';

  @override
  String get proPdfSignatureLinesTitle => 'Mostrar casillas de firma';

  @override
  String get proPdfSignatureRedo => 'Firmar de nuevo';

  @override
  String get proPdfSignatureRegister => 'Agregar firma';

  @override
  String get proPdfSignatureTitle => 'Firma del autor';

  @override
  String get proPdfTemplateLabel => 'Plantilla de documento';

  @override
  String get proPdfWatermarkHint => 'p. ej. Inspección';

  @override
  String get proPdfWatermarkLabel => 'Marca de agua';

  @override
  String get proPitchSubtitle =>
      'Desbloquee las funciones Pro de campo con un pago único.';

  @override
  String proPriceOneTimePurchase(String price) {
    return '$price · pago único';
  }

  @override
  String get proSignatureClear => 'Borrar';

  @override
  String get proSignatureDialogHint =>
      'Firme en el recuadro con el dedo o un lápiz óptico.';

  @override
  String get proSignatureDialogTitle => 'Dibujar firma';

  @override
  String get proSignatureEmptyError => 'Dibuje su firma';

  @override
  String get proSignatureSaveError => 'No se pudo guardar la firma';

  @override
  String get proTemplateBasic => 'Libreta estándar';

  @override
  String get proTemplateInspection => 'Inspección';

  @override
  String get proTemplateSubmission => 'Entrega';

  @override
  String projectBackupLastSharedTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Última copia compartida hace $days días',
      one: 'Última copia compartida hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get projectBackupLaterButton => 'Más tarde';

  @override
  String get projectBackupNeverSharedTitle =>
      'Aún no ha compartido ninguna copia de seguridad';

  @override
  String get projectBackupReminderMessage =>
      'Si pierde el teléfono o desinstala la app, perderá los registros de obra. Guarde la copia de seguridad en su correo o en la nube.';

  @override
  String get projectBackupShareButton => 'Compartir copia';

  @override
  String projectBackupShareError(String error) {
    return 'No se pudo compartir la copia: $error';
  }

  @override
  String projectBackupSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se compartieron las copias de $count proyectos.',
      one: 'Se compartió la copia de 1 proyecto.',
    );
    return '$_temp0';
  }

  @override
  String projectCardStats(int books) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books libretas',
      one: '1 libreta',
    );
    return '$_temp0';
  }

  @override
  String projectCardStatsOpen(int books, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books libretas',
      one: '1 libreta',
    );
    return '$_temp0 · $open por revisar';
  }

  @override
  String projectCardUpdated(String date) {
    return 'Actualizado · $date';
  }

  @override
  String projectDeleteConfirm(String name) {
    return '¿Eliminar el proyecto \"$name\"?\nTambién se eliminarán todas sus libretas y BM.';
  }

  @override
  String get projectDeleteDialogTitle => 'Eliminar proyecto';

  @override
  String get projectDescriptionLabel => 'Descripción (opcional)';

  @override
  String get projectDetailTabBenchmarks => 'Bancos de nivel';

  @override
  String get projectDetailTabLevelBooks => 'Libretas';

  @override
  String get projectEditDialogTitle => 'Editar proyecto';

  @override
  String get projectEmptyMessage =>
      'Cree una obra (proyecto) para registrar BM y libretas.\nPruebe primero el proyecto de ejemplo para ver el cálculo automático y la comprobación de cierre.';

  @override
  String get projectEmptyNewButton => 'Crear proyecto';

  @override
  String get projectEmptySampleButton => 'Probar proyecto de ejemplo';

  @override
  String get projectEmptyTitle => 'Agregue su primera obra';

  @override
  String get projectListQuickMemoTooltip => 'Nota rápida';

  @override
  String get projectListSettingsTooltip => 'Ajustes';

  @override
  String get projectNewDialogTitle => 'Nuevo proyecto';

  @override
  String get projectProActiveMessage =>
      'Fotos y coordenadas de TBM/BM, exportación múltiple y sin anuncios.';

  @override
  String get projectProActiveTitle => 'Pro activo';

  @override
  String get projectProGetButton => 'Obtener Pro';

  @override
  String get projectProPromoMessage =>
      'Desbloquee fotos y coordenadas de TBM/BM, exportación múltiple y elimine los anuncios.';

  @override
  String projectRecentWorkSubtitle(String project, String date) {
    return 'Reciente · $project · $date';
  }

  @override
  String get projectSampleBenchmarkDescription => 'Banco de nivel de ejemplo';

  @override
  String get projectSampleBenchmarkLocation =>
      'Bordillo frente a la oficina de obra';

  @override
  String projectSampleClosingStation(String bm) {
    return '$bm (cierre)';
  }

  @override
  String get projectSampleCreateError =>
      'No se pudo crear el proyecto de ejemplo. Inténtelo de nuevo.';

  @override
  String get projectSampleCreatedMessage =>
      'Proyecto de ejemplo creado. Abra la libreta para ver el cálculo automático.';

  @override
  String get projectSampleDescription =>
      'Ejemplo para probar el cálculo automático y la comprobación de cierre. Elimínelo si no lo necesita.';

  @override
  String get projectSampleInstrument => 'Nivel automático';

  @override
  String get projectSampleLevelBookTitle =>
      'Libreta de ejemplo (circuito BM-1)';

  @override
  String get projectSampleMemo =>
      'Datos de ejemplo. Cambie un valor y AI/cotas se recalculan automáticamente.';

  @override
  String get projectSampleName => 'Obra de ejemplo (se puede eliminar)';

  @override
  String get projectSampleSection => 'Tramo de ejemplo';

  @override
  String get projectSampleSurveyor => 'J. García';

  @override
  String get projectSampleWeather => 'Despejado';

  @override
  String get projectSiteNameLabel => 'Nombre de la obra *';

  @override
  String get projectSitesHeader => 'Obras';

  @override
  String get projectSummaryLoading => 'Organice libretas y BM por obra.';

  @override
  String projectSummaryStatsAllReviewed(int books) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books libretas',
      one: '1 libreta',
    );
    return '$_temp0 · Todo revisado';
  }

  @override
  String projectSummaryStatsOpen(int books, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books libretas',
      one: '1 libreta',
    );
    return '$_temp0 · $open por revisar';
  }

  @override
  String projectSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obras en gestión',
      one: '1 obra en gestión',
    );
    return '$_temp0';
  }

  @override
  String get purchaseCanceledMessage => 'Pago cancelado.';

  @override
  String get purchaseFailedMessage => 'El pago no se completó.';

  @override
  String get purchaseNothingToRestore => 'No hay compras para restaurar.';

  @override
  String get purchasePendingMessage => 'Procesando su pago.';

  @override
  String get purchaseProActivatedMessage => 'Lv Book Pro ya está activo.';

  @override
  String purchaseProductLoadError(String error) {
    return 'No se pudo cargar la información del producto: $error';
  }

  @override
  String purchaseProductNotFound(String productId) {
    return 'No se encontró el producto $productId en Play Console.';
  }

  @override
  String get purchaseProductNotReady =>
      'La información del producto Pro aún no está lista.';

  @override
  String purchaseRestoreError(String error) {
    return 'No se pudo restaurar la compra: $error';
  }

  @override
  String purchaseStartError(String error) {
    return 'No se pudo iniciar la compra: $error';
  }

  @override
  String get purchaseStartFailed => 'No se pudo iniciar la compra.';

  @override
  String purchaseStoreInitError(String error) {
    return 'No se pudieron iniciar las compras en la tienda: $error';
  }

  @override
  String get purchaseStoreUnavailable =>
      'Las compras en la tienda no están disponibles.';

  @override
  String get purchaseStoreUnsupportedPlatform =>
      'Las compras en la tienda no están disponibles en esta plataforma.';

  @override
  String purchaseUpdateError(String error) {
    return 'No se pudo procesar la actualización de la compra: $error';
  }

  @override
  String get quickMemoAudioMissing => 'No se encontró el archivo de audio.';

  @override
  String get quickMemoComposerTitle => 'Nota rápida de campo';

  @override
  String get quickMemoDeleteConfirm => '¿Eliminar esta nota?';

  @override
  String get quickMemoDeleteRecordingTooltip => 'Eliminar grabación';

  @override
  String get quickMemoDeleteTitle => 'Eliminar nota';

  @override
  String get quickMemoEmptyMessage =>
      'Use el botón del rayo, abajo a la izquierda, para dejar una nota de texto o de voz desde cualquier pantalla.';

  @override
  String get quickMemoEmptyTitle => 'Aún no hay notas';

  @override
  String get quickMemoMicPermissionRequired =>
      'Se necesita permiso de micrófono.';

  @override
  String get quickMemoRecordHint =>
      'Toque el micrófono para grabar una nota de voz';

  @override
  String get quickMemoRecorded =>
      'Voz grabada · toque el micrófono para volver a grabar';

  @override
  String quickMemoRecording(String time) {
    return 'Grabando · $time';
  }

  @override
  String quickMemoSaveError(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get quickMemoSavedMessage => 'Nota guardada.';

  @override
  String get quickMemoTextHint => 'Escriba una nota (opcional)';

  @override
  String get quickMemoTitle => 'Nota rápida';

  @override
  String get settingsAdsRemovedActiveSubtitle =>
      'Su compra está aplicada; no se muestran anuncios.';

  @override
  String get settingsAdsRemovedChecking =>
      'Comprobando la eliminación de anuncios';

  @override
  String get settingsAdsRemovedCheckingSubtitle =>
      'Consultando la tienda y la licencia local.';

  @override
  String get settingsAdsRemovedInactiveSubtitle =>
      'Quite todos los anuncios con un pago único en la tienda.';

  @override
  String get settingsAdsRemovedLoadError =>
      'No se pudo cargar el estado de los anuncios';

  @override
  String get settingsCheckSection => 'Control de nivelación';

  @override
  String get settingsDocumentSection => 'Documentos';

  @override
  String get settingsFeedbackSection => 'Comentarios';

  @override
  String get settingsPdfSettingsSubtitle =>
      'Empresa, plantilla, marca de agua y firma.';

  @override
  String get settingsPdfSettingsTitle => 'Ajustes del PDF de entrega';

  @override
  String get settingsPurchaseStatusSection => 'Estado de la compra';

  @override
  String get settingsRateAppSubtitle =>
      'Abra la ficha de Google Play para dejar una reseña.';

  @override
  String get settingsRateAppTitle => 'Calificar Lv Book';

  @override
  String get settingsRemoveAdsTitle => 'Quitar anuncios';

  @override
  String get settingsRestorePurchasePendingSubtitle =>
      'Consultando su historial de compras en la tienda.';

  @override
  String get settingsRestorePurchaseSubtitle =>
      'Restaure la compra de Pro que ya realizó.';

  @override
  String get settingsRestorePurchaseTitle => 'Restaurar compra';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String settingsToleranceCoefficientLabel(String unit) {
    return 'c ($unit)';
  }

  @override
  String get settingsToleranceFixedHelper =>
      '|Error de cierre| admisible para todas las libretas.';

  @override
  String settingsToleranceFixedLabel(String unit) {
    return 'Tolerancia ($unit)';
  }

  @override
  String settingsToleranceFixedSummary(String value, String unit) {
    return 'Fija ±$value $unit';
  }

  @override
  String settingsToleranceInvalid(String min, String max, String unit) {
    return 'Ingrese $min–$max $unit.';
  }

  @override
  String get settingsToleranceModeFixed => 'Fija';

  @override
  String get settingsToleranceModeSqrt => 'c·√n';

  @override
  String get settingsToleranceNote =>
      'Superarla es una advertencia; se puede exportar igualmente.';

  @override
  String settingsToleranceSqrtHelper(String unit) {
    return 'Admisible = c × √n $unit, n = estaciones del instrumento (filas con VAt).';
  }

  @override
  String settingsToleranceSqrtSummary(String value, String unit) {
    return '$value $unit × √n (n = estaciones)';
  }

  @override
  String get settingsToleranceTitle => 'Tolerancia del error de cierre';

  @override
  String get settingsToolsSection => 'Herramientas';

  @override
  String get settingsUnitFeet => 'Pies (ft)';

  @override
  String get settingsUnitMetres => 'Metros (m)';

  @override
  String get settingsUnitNote =>
      'Solo cambian las etiquetas; los números existentes no se convierten.';

  @override
  String get settingsUnitTitle => 'Unidades';
}
