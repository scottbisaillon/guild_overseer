import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/app/app.dart';

void main() {
  // Real paths instead of hash routes, so /battle is a link you can share.
  // A no-op off the web. Note that this needs the host to serve the app for
  // unknown paths — on GitHub Pages that is the 404.html copy the deploy
  // workflow makes.
  usePathUrlStrategy();
  runApp(const GuildOverseerApp());
}
