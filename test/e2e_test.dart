import 'package:test/test.dart';

import 'package:dartodef/dartodef.dart';

@Definition(name: 'myString')
const String myString = 'testString';

@Definition(name: 'myInt')
const int myInt = 0;

@Definition(name: 'myDouble')
const double myDouble = 0.0;

@Definition(name: 'myNum')
const num myNum = 0.0;

void main() {
  group('dartodef', () {
    test('should rewrite string', () => expect(myString, equals('newString')));
    test('should rewrite int', () => expect(myInt, equals(1)));
    test('should rewrite double', () => expect(myDouble, equals(1.123)));
    test('should rewrite num', () => expect(myNum, equals(1.1)));
  });
}
