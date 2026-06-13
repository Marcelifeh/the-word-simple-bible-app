import '../models/narration_segment.dart';

abstract class NarratableContent {
  List<NarrationSegment> get narrationSegments;
}
