part of '../../protoc.dart';

const _prefixMapper = 'Mapper';

class MapperGenerator extends ProtobufContainer {
  /// The name of the Dart class to generate.
  @override
  final String classname;

  /// The fully-qualified name of the entity (without any leading '.').
  @override
  final String fullName;

  @override
  List<int>? get fieldPath =>
      List.from(parent!.fieldPath!)..addAll(_fieldPathSegment);

  @override
  FileGenerator? get fileGen => parent!.fileGen!;

  @override
  String get package => parent!.package;

  @override
  final ProtobufContainer? parent;

  final DescriptorProto _descriptor;

  final List<MapperGenerator> _mapperGenerators = <MapperGenerator>[];

  final List<int> _fieldPathSegment;

  late List<ProtobufField> _fieldList;
  bool _resolved = false;

  String get _className => '$classname$_prefixMapper'.pascalCase;

  String get _entityClassName => '$classname$prefixEntity'.pascalCase;

  String get _protoClassName => classname;

  MapperGenerator._(
    DescriptorProto descriptor,
    this.parent,
    int repeatedFieldIndex,
    int fieldIdTag,
  )   : _descriptor = descriptor,
        classname = messageOrEnumClassName(
          descriptor.name,
          {},
          parent: parent?.classname ?? '',
        ),
        fullName = parent!.fullName == ''
            ? descriptor.name
            : '${parent.fullName}.${descriptor.name}',
        _fieldPathSegment = [fieldIdTag, repeatedFieldIndex] {
    for (var i = 0; i < _descriptor.nestedType.length; i++) {
      final n = _descriptor.nestedType[i];
      _mapperGenerators.add(MapperGenerator.nested(n, this, i));
    }
  }

  static const _topLevelEntityTag = 4;

  static const _nestedEntityTag = 3;

  MapperGenerator.topLevel(DescriptorProto descriptor, ProtobufContainer parent,
      int repeatedFieldIndex)
      : this._(descriptor, parent, repeatedFieldIndex, _topLevelEntityTag);

  MapperGenerator.nested(
    DescriptorProto descriptor,
    ProtobufContainer parent,
    int repeatedFieldIndex,
  ) : this._(descriptor, parent, repeatedFieldIndex, _nestedEntityTag);

  void resolve(GenerationContext ctx) {
    if (_resolved) throw StateError('message already resolved');
    _resolved = true;

    final members = messageMemberNames(_descriptor, classname, {},
        reserved: const <String>[]);

    _fieldList = <ProtobufField>[];
    for (final names in members.fieldNames) {
      final field = ProtobufField.message(names, this, ctx);
      _fieldList.add(field);
    }

    for (final m in _mapperGenerators) {
      m.resolve(ctx);
    }
  }

  void generate(IndentingWriter out) {
    out.addBlock('class $_className {', '}\n', () {
      /// From Dto
      out.println('static $_entityClassName fromDto($_protoClassName dto) {');
      out.println('  return $_entityClassName(');
      for (final field in _fieldList) {
        out.println(
            '/// ${field.baseType.descriptor.name} ${field.isRepeated}');

        final fieldName = field.memberNames!.fieldName;
        if (field.isRepeated && field.baseType.isMessage) {
          out.println(
              '$fieldName: dto.$fieldName.map(${field.baseType.onlyDart(_prefixMapper).pascalCase}.fromDto).toList(),');
        } else {
          if (field.baseType.isMessage) {
            out.println(
                '$fieldName:${field.baseType.onlyDart(_prefixMapper).pascalCase}.fromDto(dto.$fieldName),');
          } else if (field.baseType.isEnum) {
            out.println('$fieldName:  dto.$fieldName.value,');
          } else {
            out.println('$fieldName: dto.$fieldName,');
          }
        }
      }
      out.println('  );');
      out.println('}');

      /// To Dto
      out.println('static $_protoClassName toDto($_entityClassName entity) {');
      out.println('  return $_protoClassName(');
      for (final field in _fieldList) {
        out.println(
            '/// ${field.baseType.descriptor.name} ${field.isRepeated}');

        final fieldName = field.memberNames!.fieldName;

        final nullablePrefix =
            !field.isRequired ? 'entity.$fieldName != null ? ' : '';
        final nullableSuffix = !field.isRequired ? ' : null' : '';
        final nullableOptional = !field.isRequired ? '?' : '';
        final nullableRequired = !field.isRequired ? '!' : '';
        if (field.isRepeated && field.baseType.isMessage) {
          out.println(
              '$fieldName: entity.$fieldName$nullableOptional.map(${field.baseType.onlyDart(_prefixMapper).pascalCase}.toDto),');
        } else {
          if (field.baseType.isMessage) {
            out.println(
                '$fieldName: $nullablePrefix${field.baseType.onlyDart(_prefixMapper).pascalCase}.toDto(entity.$fieldName$nullableRequired)$nullableSuffix,');
          } else if (field.baseType.isEnum) {
            out.println(
                '$fieldName: $nullablePrefix${field.baseType.generator!.classname}.valueOf(entity.$fieldName$nullableRequired)$nullableSuffix,');
          } else {
            out.println('$fieldName: entity.$fieldName,');
          }
        }
      }
      out.println('  );');
      out.println('}');
    });
    for (final m in _mapperGenerators) {
      m.generate(out);
    }
  }
}
