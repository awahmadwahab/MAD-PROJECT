import 'dart:convert';
import 'dart:html' as html;

class CsvDownloadService {
  static bool downloadCsv({
    required String csvContent,
    required String filename,
  }) {
    try {
      // BOM helps Excel open UTF-8 CSV cleanly.
      final bytes = utf8.encode('\ufeff$csvContent');
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = filename;

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
