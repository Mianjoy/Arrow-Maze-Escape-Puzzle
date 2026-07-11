/// Formatea segundos restantes como `mm:ss` para la UI de partida.
String formatGameCountdown(int totalSeconds) {
  final safe = totalSeconds.clamp(0, 99 * 60 + 59);
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
