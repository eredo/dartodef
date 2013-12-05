# dartodef

dartodef is a transformer (preprocessor) for ```pub build``` which replaces variable
values on compile-time. The values can be defined in the pubspec.yaml. For
different environment values create a property in the transformer options for
dartodef and pass the name of the property as environment variable to the
```pub build``` process. **PLEASE NOTICE: dartson is in alpha status. I just wrote it in a few hours**

## Setup dartodef

**pubspec.yaml**

```yaml
name: dartodef_sample_setup
version: 0.1.0
dependencies:
  browser: any
  js: any
  dartodef: any
transformers:
  - dartodef:
      live:
        environment: 'live'
        doIt: true
      preview:
        environment: 'preview'
        doIt: false
```

**main.dart** (for example)

```dart
library sample_app;

import 'package:dartodef/dartodef.dart';

@Definition(name:'environment')
const String ENV = 'development';

class Test {
  @Definition(name:'doIt')
  static bool do = false;
}
```

Running pub build now:

```
DARTODEF=live pub build
```

If no environment is set the default values will be used.

## Available types

```yaml
...
transformers:
  - dartodef:
      live:
        string: hallo
        other_string: "hallo test"
        int: 1
        num: 1
        double: 1.1
        bool: true
        list: [1, 2, "simple", 1.1, true]
        map:
          key: "value"
          key2: 1
```

Only simple types can be used. Lists and maps will be serialized.

## What you need to know

- always import dartodef as it is. DO NOT USE "as"
- only variables that are already initialized can be used. And the initialization needs to match the type (for example mapping on string when code looks like: "String variable = null;" failes)
- use const if you want to make sure that dead is removed

## Plans for the future

- load values for each environment from dart scripts or other external files (JSON, YAML)
