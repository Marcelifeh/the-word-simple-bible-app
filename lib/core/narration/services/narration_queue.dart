import 'dart:collection';
import '../contracts/narratable_content.dart';

class NarrationQueue {
  final Queue<NarratableContent> _queue = Queue<NarratableContent>();

  void enqueue(NarratableContent content) {
    _queue.addLast(content);
  }

  void enqueueAll(List<NarratableContent> contents) {
    _queue.addAll(contents);
  }

  void enqueueNext(NarratableContent content) {
    _queue.addFirst(content);
  }

  NarratableContent? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  void clear() {
    _queue.clear();
  }

  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;
}
