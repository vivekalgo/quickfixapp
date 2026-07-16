import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

void handleCtaAction(BuildContext context, String action, String value) {
  if (action == 'Open Category') {
    context.push('/category/$value');
  } else if (action == 'Open Specific Service') {
    context.push('/service/$value');
  } else if (action == 'Open Shop') {
    context.push('/shop/$value');
  } else if (action == 'Open Internal Screen') {
    final String path = value.startsWith('/') ? value : '/$value';
    context.push(path);
  } else if (action == 'Open External URL') {
    try {
      final Uri uri = Uri.parse(value);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Safe fail
    }
  }
}
