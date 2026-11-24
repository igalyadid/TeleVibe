class ScriptConfig {
  final String text;
  final double fontSize;
  final double scrollSpeed;
  final double boxOpacity;

  ScriptConfig({
    required this.text,
    this.fontSize = 26.0,
    this.scrollSpeed = 35.0,
    this.boxOpacity = 0.55,
  });
}
