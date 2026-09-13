/// A lookup from cue id to whatever draws it.
///
/// Generic in the context it hands builders, so the registry itself carries no
/// engine dependency and can be reasoned about — and tested — without one. The
/// renderer instantiates it with its own context type.
///
/// The rule it exists to enforce: **unknown ids fail softly.** A missing skill
/// id is a content bug that should stop the loader; a missing *visual* is a
/// cosmetic gap, and a fight must never end because nobody drew a sparkle. So
/// an unregistered id trips an assertion in debug and does nothing in release.
class CueRegistry<C> {
  final Map<String, void Function(C context)> _builders =
      <String, void Function(C context)>{};

  Iterable<String> get registered => _builders.keys;

  bool knows(String id) => _builders.containsKey(id);

  void register(String id, void Function(C context) builder) {
    assert(
      !_builders.containsKey(id),
      'Cue "$id" is already registered; ids must be unique.',
    );
    _builders[id] = builder;
  }

  /// Plays [id], if there is anything to play.
  ///
  /// A null id is the ordinary way to say "nothing here", not an omission.
  void play(String? id, C context) {
    if (id == null) {
      return;
    }
    final void Function(C context)? builder = _builders[id];
    assert(
      builder != null,
      'No cue registered for "$id". Register it, or stop naming it in content.',
    );
    builder?.call(context);
  }
}
