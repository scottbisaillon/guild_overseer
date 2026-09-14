import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/definition_index.dart';

class _Thing {
  const _Thing(this.id);

  final String id;
}

/// The half of the "fail loudly at load, softly at render" rule that is
/// supposed to be loud.
void main() {
  DefinitionIndex<_Thing> indexOf(List<String> ids) => DefinitionIndex<_Thing>(
        ids.map(_Thing.new),
        idOf: (_Thing thing) => thing.id,
        label: 'skill',
      );

  group('DefinitionIndex', () {
    test('finds what it was built with', () {
      expect(indexOf(<String>['a', 'b']).require('b').id, 'b');
    });

    test('knows what it does not have', () {
      final DefinitionIndex<_Thing> index = indexOf(<String>['a']);

      expect(index.knows('a'), isTrue);
      expect(index.knows('nope'), isFalse);
      expect(index.maybe('nope'), isNull);
    });

    test('an unknown id throws, naming the id and what it is', () {
      expect(
        () => indexOf(<String>['strike']).require('strke'),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.name, 'name', 'skill id')
              .having((ArgumentError e) => e.invalidValue, 'value', 'strke')
              .having(
                (ArgumentError e) => e.message.toString(),
                'message',
                contains('strike'),
              ),
        ),
      );
    });

    test('requireAll keeps the order it was asked in', () {
      expect(
        indexOf(<String>['a', 'b', 'c'])
            .requireAll(<String>['c', 'a'])
            .map((_Thing t) => t.id),
        <String>['c', 'a'],
      );
    });

    test('requireAll throws on the first unknown rather than half loading', () {
      expect(
        () => indexOf(<String>['a']).requireAll(<String>['a', 'gone']),
        throwsArgumentError,
      );
    });

    test('keepKnown drops what is gone, for loading an older save', () {
      expect(
        indexOf(<String>['a', 'b'])
            .keepKnown(<String>['a', 'gone', 'b'])
            .map((_Thing t) => t.id),
        <String>['a', 'b'],
      );
    });
  });
}
