abstract final class AppDateFormats {
  static String isoUtc(DateTime d) => d.toUtc().toIso8601String();
}
