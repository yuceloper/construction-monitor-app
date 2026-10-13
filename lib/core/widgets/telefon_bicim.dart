/// Telefon numarasini okunur bicime cevirir.
///
/// Sunucudan "05554445566" gibi bitisik geliyor; ekranda gruplanmis
/// halde duruyor. Tanimadigi bir bicim gelirse numaraya dokunmuyor.
String telefonBicimle(String ham) {
  final rakamlar = ham.replaceAll(RegExp(r'[^0-9+]'), '');
  final ulkeKodlu = rakamlar.startsWith('+');
  final sade = rakamlar.replaceAll('+', '');

  // +90 555 444 55 66
  if (ulkeKodlu && sade.length == 12 && sade.startsWith('90')) {
    final n = sade.substring(2);
    return '+90 ${n.substring(0, 3)} ${n.substring(3, 6)} '
        '${n.substring(6, 8)} ${n.substring(8)}';
  }
  // 0555 444 55 66
  if (!ulkeKodlu && sade.length == 11 && sade.startsWith('0')) {
    return '${sade.substring(0, 4)} ${sade.substring(4, 7)} '
        '${sade.substring(7, 9)} ${sade.substring(9)}';
  }
  // 555 444 55 66 -> basina 0 eklenmeden gruplanir
  if (!ulkeKodlu && sade.length == 10) {
    return '${sade.substring(0, 3)} ${sade.substring(3, 6)} '
        '${sade.substring(6, 8)} ${sade.substring(8)}';
  }
  return ham.trim();
}
