import 'dart:html';
import '../lib/test_lib.dart';

main() {
  document.body.innerHtml += OUR_STRING + '<br />';

  OUR_LIST.forEach((item) {
    document.body.innerHtml += item + '<br />';
  });

  OUR_MAP.forEach((k, v) => document.body.innerHtml += k + ' = ' + v + '<br />');

  if (OUR_BOOLEAN) {
    document.body.innerHtml += 'true';
  }

  if (!OUR_BOOLEAN) {
    document.body.innerHtml += 'WTF IS GOING UP?';
  }
  
  if (!Test.CLASS_BOOL) {
    document.body.innerHtml += 'FAILED';
  }
}
