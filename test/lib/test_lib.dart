library test_lib;

import 'package:dartodef/dartodef.dart';

@Definition(name:'string')
const String OUR_STRING = 'test';

@Definition(name:'bool')
const bool OUR_BOOLEAN = false;

@Definition(name:'num')
const num OUR_NUM = 0;

@Definition(name:'int')
const int OUR_INT = 0;

@Definition(name:'double')
const double OUR_DOUBLE = 0.0;

@Definition(name:'map')
const Map OUR_MAP = const {};

@Definition(name:'list')
const List OUR_LIST = const [];

class Test {
  @Definition(name:'test.bool')
  static const bool CLASS_BOOL = false;
}