import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons used across the designs (24×24 grid, round caps).
enum TTIcons {
  plus('<path d="M12 5v14M5 12h14"/>'),
  arrowRight('<path d="M5 12h14M13 6l6 6-6 6"/>'),
  back('<path d="M19 12H5M11 6l-6 6 6 6"/>'),
  chevronDown('<path d="m6 9 6 6 6-6"/>'),
  chevronRight('<path d="m9 6 6 6-6 6"/>'),
  close('<path d="M6 6l12 12M18 6 6 18"/>'),
  bell('<path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2.2 2.2 0 0 0 4 0"/>'),
  smile('<circle cx="12" cy="12" r="8.5"/><path d="M8.5 14c.9 1.3 2.1 2 3.5 2s2.6-.7 3.5-2"/><path d="M9 9.5h.01M15 9.5h.01"/>'),
  calendar('<rect x="4" y="5.5" width="16" height="14" rx="3"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"/>'),
  globe('<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.5 3.5 5.3 3.5 8.5s-1.1 6-3.5 8.5c-2.4-2.5-3.5-5.3-3.5-8.5s1.1-6 3.5-8.5z"/>'),
  coins('<ellipse cx="12" cy="7" rx="7" ry="3"/><path d="M5 7v5c0 1.7 3.1 3 7 3s7-1.3 7-3V7"/><path d="M5 12v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5"/>'),
  food('<path d="M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10"/><path d="M17 21V3c-2 1.5-3 4-3 7h3"/>'),
  travel('<rect x="5" y="4" width="14" height="13" rx="3"/><path d="M5 11h14M8 20v-3M16 20v-3"/><path d="M8.5 14h.01M15.5 14h.01"/>'),
  fun('<path d="M7 8h10a4 4 0 0 1 4 4v1.5a2.5 2.5 0 0 1-4.6 1.4L15 13H9l-1.4 1.9A2.5 2.5 0 0 1 3 13.5V12a4 4 0 0 1 4-4z"/><path d="M7.5 10.5v3M6 12h3M15.5 11.5h.01M17.5 12.5h.01"/>'),
  home('<path d="M4 11.5 12 5l8 6.5V19a1.5 1.5 0 0 1-1.5 1.5H15v-5.5H9v5.5H5.5A1.5 1.5 0 0 1 4 19z"/>'),
  history('<path d="M5 7h14M5 12h14M5 17h9"/>'),
  jar('<rect x="6" y="8" width="12" height="12" rx="3"/><path d="M8 4.5h8v3.5H8z"/>'),
  settings('<circle cx="12" cy="12" r="3"/><path d="M12 3.5v2.2M12 18.3v2.2M3.5 12h2.2M18.3 12h2.2M6 6l1.6 1.6M16.4 16.4 18 18M6 18l1.6-1.6M16.4 7.6 18 6"/>'),
  grow('<path d="M4 17l6-6 4 4 6-7"/><path d="M15 8h5v5"/>'),
  chat('<path d="M5 6h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-7l-4 3v-3H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z"/>'),
  arrowDown('<path d="M12 5v12M6 11l6 6 6-6"/>'),
  arrowUp('<path d="M12 19V7M6 13l6-6 6 6"/>'),
  check('<path d="m5 12.5 4.5 4.5L19 7.5"/>');

  final String paths;
  const TTIcons(this.paths);
}

class TTIcon extends StatelessWidget {
  final TTIcons icon;
  final Color color;
  final double size;
  final double strokeWidth;

  const TTIcon(this.icon, {super.key, required this.color, this.size = 20, this.strokeWidth = 2.2});

  @override
  Widget build(BuildContext context) {
    final svg = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000000" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round" '
        'xmlns="http://www.w3.org/2000/svg">${icon.paths}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
