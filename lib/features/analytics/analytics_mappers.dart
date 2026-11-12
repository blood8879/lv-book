import '../fieldbook/domain/misclosure.dart';
import '../fieldbook/domain/reduction.dart';
import 'analytics_events.dart';

// App enums → fixed `AnalyticsValues` strings (never `Enum.name`, so a
// renamed enum cannot silently change or leak a reported value).

String analyticsReductionMethod(ReductionMethod method) => switch (method) {
  ReductionMethod.heightOfInstrument => AnalyticsValues.heightOfInstrument,
  ReductionMethod.riseAndFall => AnalyticsValues.riseAndFall,
};

String analyticsLengthUnit(LengthUnit unit) => switch (unit) {
  LengthUnit.metres => AnalyticsValues.metres,
  LengthUnit.feet => AnalyticsValues.feet,
};

String analyticsToleranceMode(MisclosureToleranceMode mode) => switch (mode) {
  MisclosureToleranceMode.fixed => AnalyticsValues.fixed,
  MisclosureToleranceMode.sqrtSetups => AnalyticsValues.sqrtSetups,
  MisclosureToleranceMode.sqrtDistance => AnalyticsValues.sqrtDistance,
};

/// pass / fail against the closing RL, or no_reference without one.
String analyticsClosureResult(bool? withinTolerance) =>
    switch (withinTolerance) {
      true => AnalyticsValues.pass,
      false => AnalyticsValues.fail,
      null => AnalyticsValues.noReference,
    };
