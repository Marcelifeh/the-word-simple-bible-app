/// A single insight block inside a [DevotionalModel].
class DevotionalSection {
  final String heading;
  final String body;
  final String icon; // emoji displayed in the tile header

  const DevotionalSection({
    required this.heading,
    required this.body,
    required this.icon,
  });
}
