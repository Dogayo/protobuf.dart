part of '../../protoc.dart';

const _prefixEnum = 'Enum';

class EnumEntityGenerator extends ProtobufContainer {
  /// The name of the Dart class to generate.
  @override
  final String classname;

  /// The fully-qualified name of the entity (without any leading '.').
  @override
  final String fullName;

  @override
  List<int> get fieldPath =>
      List.from(parent.fieldPath!)..addAll(_fieldPathSegment);

  @override
  FileGenerator? get fileGen => parent.fileGen!;

  @override
  String get package => parent.package;

  @override
  final ProtobufContainer parent;

  final EnumDescriptorProto _descriptor;
  final List<EnumValueDescriptorProto> _canonicalValues =
      <EnumValueDescriptorProto>[];
  final List<EnumAlias> _aliases = <EnumAlias>[];
  final List<int> _originalCanonicalIndices = <int>[];
  final List<int> _fieldPathSegment;

  /// Maps the name of an enum value to the Dart name we will use for it.
  final Map<String, String> dartNames = <String, String>{};
  final List<int> _originalAliasIndices = <int>[];

  String get _className => '$classname$_prefixEnum'.pascalCase;

  EnumEntityGenerator._(
    EnumDescriptorProto descriptor,
    this.parent,
    int repeatedFieldIndex,
    int fieldIdTag,
  )   : _fieldPathSegment = [fieldIdTag, repeatedFieldIndex],
        classname = messageOrEnumClassName(descriptor.name, {},
            parent: parent.classname ?? ''),
        fullName = parent.fullName == ''
            ? descriptor.name
            : '${parent.fullName}.${descriptor.name}',
        _descriptor = descriptor {
    final usedNames = {...reservedEnumNames};
    for (var i = 0; i < descriptor.value.length; i++) {
      final value = descriptor.value[i];
      final canonicalValue =
          descriptor.value.firstWhere((v) => v.number == value.number);
      if (value == canonicalValue) {
        _canonicalValues.add(value);
        _originalCanonicalIndices.add(i);
      } else {
        _aliases.add(EnumAlias(value, canonicalValue));
        _originalAliasIndices.add(i);
      }
      dartNames[value.name] = disambiguateName(
          avoidInitialUnderscore(value.name), usedNames, enumSuffixes());
    }
  }

  static const _topLevelFieldTag = 5;
  static const _nestedFieldTag = 4;

  EnumEntityGenerator.topLevel(EnumDescriptorProto descriptor,
      ProtobufContainer parent, int repeatedFieldIndex)
      : this._(descriptor, parent, repeatedFieldIndex, _topLevelFieldTag);

  EnumEntityGenerator.nested(
    EnumDescriptorProto descriptor,
    ProtobufContainer parent,
    int repeatedFieldIndex,
  ) : this._(descriptor, parent, repeatedFieldIndex, _nestedFieldTag);

  void generate(IndentingWriter out) {
    out.println('enum $_className {');
    for (var i = 0; i < _canonicalValues.length; i++) {
      final sererated = i == _canonicalValues.length - 1 ? ';' : ',';
      final value = _canonicalValues[i];
      out.println('${value.name.camelCase}(${value.number})$sererated');
    }
    out.println();
    out.println('const $_className(this.value);');
    out.println();
    out.println('final int value;');
    out.println();
    out.println('}');
    return;
    for (var i = 0; i < _canonicalValues.length; i++) {
      final value = _canonicalValues[i];
      value.name;
      final name = dartNames[value.name]!;
      final fieldPathSegment = List.from(fieldPath)
        ..addAll([_fieldPathSegment[0], _originalCanonicalIndices[i]]);

      final commentBlock = fileGen?.commentBlock(fieldPathSegment.cast<int>());
      if (commentBlock != null) {
        out.println(commentBlock);
      }
      out.println('$name,');
    }

    if (_aliases.isNotEmpty) {
      for (var i = 0; i < _aliases.length; i++) {
        final alias = _aliases[i];
        final name = dartNames[alias.value.name]!;
        final fieldPathSegment = List.from(fieldPath)
          ..addAll([_fieldPathSegment[0], _originalAliasIndices[i]]);
        out.println('$name: $name,');
      }
    }
    out.println('}');
  }
}
