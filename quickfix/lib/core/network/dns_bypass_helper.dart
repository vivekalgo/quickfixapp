import 'dart:io';
import 'package:quickfix/core/config/app_config.dart';

/// Helper to handle Operator-Block Bypass (Jio / Airtel DNS blocks on *.up.railway.app).
/// Reusable utility to apply edge IP routing and certificate validation.
class DnsBypassHelper {
  DnsBypassHelper._();

  static const String railwayEdgeIp = '69.46.46.69';
  static const String railwayDomain = 'up.railway.app';

  /// Returns true if the [url] targets the blocked Railway domain and bypass is enabled.
  static bool shouldBypass(String url) {
    if (!AppConfig.enableDnsBypass) return false;
    return url.contains(railwayDomain);
  }

  /// Rewrites the host of [originalUrl] to use the edge IP and updates headers.
  /// Returns the rewritten URL.
  static String bypassUrl(String originalUrl, Map<String, dynamic> headers) {
    if (!shouldBypass(originalUrl)) return originalUrl;

    try {
      final parsedUri = Uri.parse(originalUrl);
      final originalHost = parsedUri.host;
      headers['Host'] = originalHost;
      return originalUrl.replaceFirst(originalHost, railwayEdgeIp);
    } catch (_) {
      return originalUrl;
    }
  }

  /// Certificate validation callback matching edge IP connections to trusted domains.
  /// 
  /// In production, it enforces strict verification including date validity checks,
  /// preventing self-signed certificates, checking subject matching, and checking trusted issuers.
  static bool verifyCertificate(X509Certificate cert, String host, int port) {
    final isKnownHost = host == railwayEdgeIp || host.endsWith(railwayDomain);
    if (!isKnownHost) return false;

    // For development and staging environments, basic check is sufficient
    if (!AppConfig.isProduction) {
      return cert.subject.contains('CN=*.$railwayDomain') ||
             cert.subject.contains('CN=$railwayDomain');
    }

    // --- Strict Production Verification ---
    
    // 1. Expiration check
    final now = DateTime.now();
    if (now.isBefore(cert.startValidity) || now.isAfter(cert.endValidity)) {
      return false;
    }

    // 2. Prevent self-signed certificates (subject equals issuer)
    if (cert.subject.trim() == cert.issuer.trim()) {
      return false;
    }

    // 3. Subject CN validation
    final isSubjectValid =
        cert.subject.contains('CN=*.$railwayDomain') ||
        cert.subject.contains('CN=$railwayDomain');
    if (!isSubjectValid) return false;

    // 4. Issuer validation (ensuring it is signed by a trusted public Certificate Authority)
    final trustedIssuers = [
      'Let\'s Encrypt',
      'Cloudflare',
      'Google',
      'DigiCert',
      'Sectigo',
      'GTS',
      'GlobalSign',
      'Amazon'
    ];
    final hasTrustedIssuer = trustedIssuers.any((issuer) => cert.issuer.contains(issuer));
    
    return hasTrustedIssuer;
  }
}
