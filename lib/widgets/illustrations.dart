import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

String _coin(num cx, num cy, num r) =>
    '<circle cx="$cx" cy="$cy" r="$r" fill="#F5A623"/><circle cx="$cx" cy="${cy - 1}" r="${r - 3}" fill="#FFC83D"/>'
    '<rect x="${cx - 2}" y="${cy - r / 2 - 1}" width="4" height="$r" rx="2" fill="#F5A623"/>';

String _coinThin(num cx, num cy, num r) =>
    '<circle cx="$cx" cy="$cy" r="$r" fill="#F5A623"/><circle cx="$cx" cy="${cy - 1}" r="${r - 3}" fill="#FFC83D"/>'
    '<rect x="${cx - 1.6}" y="${cy - r / 2 - 1}" width="3.2" height="$r" rx="1.6" fill="#F5A623"/>';

String _star(num cx, num cy, num s, String c) =>
    '<path d="M$cx ${cy - s} Q$cx $cy ${cx + s} $cy Q$cx $cy $cx ${cy + s} Q$cx $cy ${cx - s} $cy Q$cx $cy $cx ${cy - s}Z" fill="$c"/>';

/// Coin jar with a falling coin (Welcome / Add kid).
final String coinJarSvg = '''
<svg width="150" height="140" viewBox="0 0 150 140" fill="none" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="75" cy="131" rx="46" ry="6" fill="#16425B" fill-opacity="0.08"/>
<path d="M39 54h72a10 10 0 0 1 10 10v46a20 20 0 0 1-20 20H49a20 20 0 0 1-20-20V64a10 10 0 0 1 10-10z" fill="#BDE9F8"/>
${_coin(57, 110, 13)}${_coin(83, 114, 13)}${_coin(102, 102, 11)}${_coin(70, 90, 12)}${_coin(93, 83, 10)}
<rect x="40" y="64" width="7" height="40" rx="3.5" fill="#FFFFFF" fill-opacity="0.75"/>
<rect x="44" y="38" width="62" height="20" rx="9" fill="#FF6B57"/>
<rect x="63" y="45" width="24" height="5" rx="2.5" fill="#16425B" fill-opacity="0.35"/>
${_coin(75, 20, 12)}
${_star(122, 30, 9, '#FF5FA2')}${_star(28, 30, 7, '#8E5BE8')}${_star(130, 70, 6, '#4FC3F7')}
</svg>''';

/// Stack of coins (Home balance card).
final String coinStackSvg = '''
<svg width="96" height="90" viewBox="0 0 96 90" fill="none" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="46" cy="84" rx="34" ry="5" fill="#16425B" fill-opacity="0.08"/>
<rect x="14" y="66" width="44" height="14" rx="7" fill="#F5A623"/><rect x="14" y="62" width="44" height="14" rx="7" fill="#FFC83D"/>
<rect x="18" y="50" width="44" height="14" rx="7" fill="#F5A623"/><rect x="18" y="46" width="44" height="14" rx="7" fill="#FFC83D"/>
<rect x="12" y="34" width="44" height="14" rx="7" fill="#F5A623"/><rect x="12" y="30" width="44" height="14" rx="7" fill="#FFC83D"/>
${_coin(72, 62, 16)}
<path d="M80 8 Q80 16 88 16 Q80 16 80 24 Q80 16 72 16 Q80 16 80 8Z" fill="#FF5FA2"/>
</svg>''';

/// Jar with a money tree growing out of it (Jars empty state, Jar detail).
final String moneyTreeJarSvg = '''
<svg width="210" height="180" viewBox="0 0 210 180" fill="none" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="105" cy="170" rx="58" ry="7" fill="#16425B" fill-opacity="0.08"/>
<path d="M105 128C105 104 105 80 105 46" stroke="#1FA39A" stroke-width="5" stroke-linecap="round"/>
<path d="M105 66c0-18 13-29 33-29 0 18-13 29-33 29z" fill="#1FA39A"/>
<path d="M105 82c0-15-12-24-28-24 0 15 12 24 28 24z" fill="#5FD3C9"/>
<path d="M105 50c0-10-7-16-17-16 0 10 7 16 17 16z" fill="#5FD3C9"/>
${_coinThin(140, 32, 10)}${_coinThin(74, 54, 9)}${_coinThin(86, 28, 8)}
<path d="M63 78h84a12 12 0 0 1 12 12v50a24 24 0 0 1-24 24H75a24 24 0 0 1-24-24V90a12 12 0 0 1 12-12z" fill="#BDE9F8"/>
<rect x="66" y="66" width="78" height="16" rx="8" fill="#93D8F0"/>
${_coinThin(82, 146, 14)}${_coinThin(110, 150, 14)}${_coinThin(133, 138, 12)}${_coinThin(96, 128, 12)}${_coinThin(122, 118, 10)}
<rect x="62" y="92" width="8" height="48" rx="4" fill="#FFFFFF" fill-opacity="0.75"/>
${_star(176, 62, 9, '#FF5FA2')}${_star(34, 96, 7, '#8E5BE8')}${_star(184, 120, 6, '#4FC3F7')}${_star(40, 40, 5, '#FFC83D')}
</svg>''';

/// Sprout in a pot on a white tile (Home: start an investment jar).
const String sproutTileSvg = '''
<svg width="52" height="52" viewBox="0 0 52 52" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="52" height="52" rx="18" fill="#FFFFFF"/>
<path d="M15 32h22l-2.3 10a3 3 0 0 1-2.9 2.3H20.2a3 3 0 0 1-2.9-2.3z" fill="#FF6B57"/>
<rect x="13" y="28" width="26" height="6" rx="3" fill="#E8543F"/>
<path d="M26 28V19" stroke="#1FA39A" stroke-width="3" stroke-linecap="round"/>
<path d="M26 20c0-5 4-8 9-8 0 5-4 8-9 8z" fill="#1FA39A"/><path d="M26 23c0-4-3-7-8-7 0 4 3 7 8 7z" fill="#5FD3C9"/>
</svg>''';

/// Small jar on a white tile (Home: active jar card).
const String jarTileSvg = '''
<svg width="44" height="44" viewBox="0 0 44 44" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="44" height="44" rx="15" fill="#FFFFFF"/>
<path d="M14 16h16a3 3 0 0 1 3 3v12a6 6 0 0 1-6 6H17a6 6 0 0 1-6-6V19a3 3 0 0 1 3-3z" fill="#BDE9F8"/>
<rect x="14" y="11" width="16" height="6" rx="3" fill="#8E5BE8"/>
<circle cx="18" cy="31" r="4.5" fill="#F5A623"/><circle cx="18" cy="30.4" r="2.5" fill="#FFC83D"/>
<circle cx="26" cy="32" r="4.5" fill="#F5A623"/><circle cx="26" cy="31.4" r="2.5" fill="#FFC83D"/>
<circle cx="22" cy="25" r="4" fill="#F5A623"/><circle cx="22" cy="24.4" r="2" fill="#FFC83D"/>
</svg>''';

String coinSvg() =>
    '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="11" fill="#F5A623"/><circle cx="12" cy="11.4" r="8.6" fill="#FFC83D"/><rect x="10.8" y="6.8" width="2.4" height="9.2" rx="1.2" fill="#F5A623"/></svg>';

String sparkleSvg(String color) =>
    '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 0Q12 12 24 12Q12 12 12 24Q12 12 0 12Q12 12 12 0Z" fill="$color"/></svg>';

class Illustration extends StatelessWidget {
  final String svg;
  final double? width;
  final double? height;
  const Illustration(this.svg, {super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: width, height: height);
}
