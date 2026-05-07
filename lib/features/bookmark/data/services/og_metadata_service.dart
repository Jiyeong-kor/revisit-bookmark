import 'package:http/http.dart' as http;

import '../../domain/entities/og_metadata.dart';

class OgMetadataService {
  static const _timeout = Duration(seconds: 10);

  Future<OgMetadata> fetch(String rawUrl) async {
    final url = _normalizeUrl(rawUrl);
    final uri = Uri.parse(url);
    final sourceDomain = uri.host.replaceFirst('www.', '');

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 (compatible; bot)'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return OgMetadata(sourceDomain: sourceDomain);
      }

      final html = response.body;
      return OgMetadata(
        title: _extractOg(html, 'title') ?? _extractTitleTag(html),
        description: _extractOg(html, 'description'),
        imageUrl: _extractOg(html, 'image'),
        sourceDomain: sourceDomain,
      );
    } catch (_) {
      return OgMetadata(sourceDomain: sourceDomain);
    }
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  /// og:property 추출 — attribute 순서가 뒤바뀐 경우도 처리
  String? _extractOg(String html, String property) {
    final patterns = [
      RegExp(
        "property=[\"']og:$property[\"'][^>]*content=[\"']([^\"']+)[\"']",
        caseSensitive: false,
      ),
      RegExp(
        "content=[\"']([^\"']+)[\"'][^>]*property=[\"']og:$property[\"']",
        caseSensitive: false,
      ),
    ];

    for (final regex in patterns) {
      final value = regex.firstMatch(html)?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// og:title이 없을 때 <title> 태그 fallback
  String? _extractTitleTag(String html) {
    final regex = RegExp('<title[^>]*>([^<]+)</title>', caseSensitive: false);
    return regex.firstMatch(html)?.group(1)?.trim();
  }
}
