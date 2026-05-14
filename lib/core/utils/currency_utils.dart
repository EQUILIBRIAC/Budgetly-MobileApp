abstract final class CurrencyUtils {
  static String formatSymbol(bool isUsd) => isUsd ? r'$' : 'S/ ';
}
