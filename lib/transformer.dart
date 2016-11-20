// Copyright (c) 2016, Eric Schneller.
// Use of this source code is governed by a MIT-license that can
// be found in the LICENSE file.

// Thanks to the Dart authors for their code in package:observe/transformer.dart
// This transformer is using some parts of their code. For further information
// check out: https://github.com/dart-lang/bleeding_edge/blob/master/dart/pkg/observe/lib/transformer.dart

library dartodef.transformer;

import './dartodef.dart';
import 'dart:async';
import 'dart:io';
//import 'dart:mirrors';
import 'dart:convert' show JSON;
import 'package:barback/barback.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart' show SourceFile;

class DartodefTransformer extends Transformer {
  static final String DARTODEF_ENV = 'DARTODEF';
  Map<String, dynamic> _definitions;

  DartodefTransformer(this._definitions) {
    // check if environment variables are passed to the build process
    if (Platform.environment[DARTODEF_ENV] != null) {
      var env = Platform.environment[DARTODEF_ENV];

      if (_definitions[env] != null) {
        _definitions = _definitions[env];
      } else {
        print('DARTODEF WARNING: Environment variable passed but no matching ' +
          'variable in definitions map found');
      }
    }
  }

  DartodefTransformer.asPlugin(BarbackSettings settings) :
    this(_readDefinitions(settings.configuration));

  Future<bool> isPrimary(AssetId input) {
    // TODO(eric): Not the best way. It's necessary to import the dartodef library
    // without any "as" definition to ensure the functionality.
    return new Future.value(input.extension == '.dart');
  }

  Future apply(Transform transform) {
    Completer comp = new Completer();

    return transform.primaryInput.readAsString()
      .then((String content) {
        var id = transform.primaryInput.id;
        // TODO(sigmund): improve how we compute this url
        var url = id.path.startsWith('lib/')
            ? 'package:${id.package}/${id.path.substring(4)}' : id.path;

        var sourceFile = new SourceFile(content, url: url);
        var unit = _parseCompilationUnit(content);
        var code = new TextEditTransaction(content, sourceFile);

        for (var dec in unit.declarations) {
          _checkDeclaration(dec, code, transform.logger);
        }

        if (!code.hasEdits) {
          transform.addOutput(transform.primaryInput);
          return;
        }

        var printer = code.commit();
        printer.build(url);
        transform.addOutput(new Asset.fromString(id, printer.text));
      });
  }

  _checkDeclaration(Declaration dec, TextEditTransaction code, TransformLogger logger, {Definition definition}) {
    Definition def;

    if (dec is VariableDeclaration) {
      def = _getDefinition(dec);
     // make sure the definition of top level variables is passed
      if (def == null && definition != null) {
        def = definition;
      }

      if (def != null) {
        var defValue = _definitions[def.name];

        if (dec.initializer == null) {
          logger.warning('Definition "' + def.name + '" set for a not initialized variable.' +
              'Currently it\'s only possbile to use @Definition with already defined values.');
        }

        if (_definitions[def.name] != null) {
          if (dec.initializer is SimpleStringLiteral &&
            defValue is String) {
            // set string declaration
            code.edit(dec.initializer.offset, dec.initializer.end, '"' + _definitions[def.name] + '"');
            logger.info('Set value: "' + defValue + '" for: ' + def.name);
          } else if (_isSimpleDeclaration(dec.initializer, defValue)) {
            // set declarations for int, num, bool, double
            code.edit(dec.initializer.offset, dec.initializer.end, defValue.toString());
            logger.info('Set value: ' + defValue.toString() + ' for: ' + def.name);
          } else if (_isSerializableDeclaration(dec.initializer, defValue)) {
            // serialize maps and lists and set them (add const if necessary)
            var initStr = (dec.isConst ? 'const ' : '') + JSON.encode(defValue);
            code.edit(dec.initializer.offset, dec.initializer.end, initStr);
            logger.info('Set value: ' + initStr + ' for: ' + def.name);
          } else {
            // TODO(eric): Create a better error message with the actual type in it.
            logger.warning('Missmatched type, definition is not matching the type.');
          }

        } else {
          logger.warning('Definition for: ' + def.name + ' not set.');
        }
      }
    } else if (dec is TopLevelVariableDeclaration) {
      // TopLevelVariables may contain the definition but the actual variables not...
      def = _getDefinition(dec);
      dec.variables.variables.forEach((e) => _checkDeclaration(e, code, logger, definition: def));
    } else if (dec is ClassDeclaration) {
      // run through the members of a class
      if (dec.members != null) {
        dec.members.forEach((e) => _checkDeclaration(e, code, logger));
      }
    } else if (dec is FieldDeclaration) {
      // this appears in class members
      if (dec.fields != null && dec.fields.variables != null) {
        def = _getDefinition(dec);
        dec.fields.variables.forEach((e) => _checkDeclaration(e, code, logger, definition: def));
      }
    } else {
// ignore it
//      print('Unknown declaration found: ' + MirrorSystem.getName(reflect(dec).type.simpleName));
    }
  }

  // Maybe extend this function later... just a placeholder so far.
  static Map<String, dynamic> _readDefinitions(Map definitions) {
    return definitions;
  }
}

/**
 * Checks if the initializer matches a simple type. That way we can pass the
 * value directly using value.toString().
 */
bool _isSimpleDeclaration(Expression init, dynamic value) =>
    (init is BooleanLiteral && value is bool) ||
    (init is IntegerLiteral && (value is num || value is int)) ||
    (init is DoubleLiteral && value is double);

/**
 * Checks if the initializer matches a type that needs to be serialized before
 * defined in the code. Maps and Lists can only contain constant types.
 */
_isSerializableDeclaration(Expression init, dynamic value) =>
    (init is MapLiteral && value is Map) ||
    (init is ListLiteral && value is List);

/**
 * Checks if the Declaration has a Definition Annotation.abstract
 *  Returns null if not.
 */
Definition _getDefinition(AnnotatedNode node) {
  Definition def;
  Map argsMap = {};
  bool found = false;

  for (var annotation in node.metadata) {
    // TODO(eric): This is not the best way if dartodef is imported as X
    if(annotation.name.name == 'Definition') {
      found = true;
      annotation.arguments.arguments.forEach((arg) {
        if (arg is NamedExpression) {
          var name = arg.name.label.name;
          var value = arg.expression.value;

          argsMap[name] = value;
        }
      });
      break;
    }
  }

  if (found) {
    def = new Definition(name:argsMap['name']);
  }

  return def;
}

class _ErrorCollector extends AnalysisErrorListener {
  final errors = <AnalysisError>[];
  onError(error) => errors.add(error);
}

CompilationUnit _parseCompilationUnit(String code) {
  var errorListener = new _ErrorCollector();
  var reader = new CharSequenceReader(code);
  var scanner = new Scanner(null, reader, errorListener);
  var token = scanner.tokenize();
  var parser = new Parser(null, errorListener);
  return parser.parseCompilationUnit(token);
}
