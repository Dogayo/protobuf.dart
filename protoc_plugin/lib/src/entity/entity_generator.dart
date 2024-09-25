part of '../../protoc.dart';

const _prefixEntity = 'Entity';

class EntityGenerator extends ProtobufContainer {
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

  String get _className => '$classname$_prefixEntity';

  final List<int> _fieldPathSegment;
  final DescriptorProto _descriptor;
  final List<EntityGenerator> _entityGenerators = <EntityGenerator>[];
  final List<EnumEntityGenerator> _enumGenerators = <EnumEntityGenerator>[];

  late List<ProtobufField> _fieldList;
  bool _resolved = false;

  EntityGenerator._(
    DescriptorProto descriptor,
    this.parent,
    int repeatedFieldIndex,
    int fieldIdTag,
  )   : _descriptor = descriptor,
        classname = messageOrEnumClassName(
          descriptor.name,
          {},
          parent: parent?.classname ?? '',
        ).pascalCase,
        fullName = parent!.fullName == ''
            ? descriptor.name
            : '${parent.fullName}.${descriptor.name}',
        _fieldPathSegment = [fieldIdTag, repeatedFieldIndex] {
    for (var i = 0; i < _descriptor.nestedType.length; i++) {
      final n = _descriptor.nestedType[i];
      _entityGenerators.add(EntityGenerator.nested(n, this, i));
    }

    for (var i = 0; i < _descriptor.enumType.length; i++) {
      final e = _descriptor.enumType[i];
      _enumGenerators.add(EnumEntityGenerator.nested(e, this, i));
    }
  }

  static const _topLevelEntityTag = 4;

  static const _nestedEntityTag = 3;

  EntityGenerator.topLevel(DescriptorProto descriptor, ProtobufContainer parent,
      int repeatedFieldIndex)
      : this._(descriptor, parent, repeatedFieldIndex, _topLevelEntityTag);

  EntityGenerator.nested(
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

    for (final m in _entityGenerators) {
      m.resolve(ctx);
    }
  }

  void generate(IndentingWriter out) {
    /// Start class
    out.println('class $_className extends Equatable  {');

    /// Contsructor
    out.println();
    out.println('const $_className({');
    for (final field in _fieldList) {
      final keyword = field.isRequired ? 'required' : '';
      out.println('$keyword this.${field.memberNames!.fieldName},');
    }
    out.println('});');
    out.println();

    /// Final fields
    for (final field in _fieldList) {
      final nullable = !field.isRequired ? '?' : '';
      if (field.isRepeated) {
        out.println(
            'final List<${field.baseType.onlyDart(_prefixEntity)}>$nullable ${field.memberNames!.fieldName};');
      } else {
        out.println(
            'final ${field.baseType.onlyDart(_prefixEntity)}$nullable ${field.memberNames!.fieldName};');
      }
    }
    out.println();

    /// Copy with
    out.println('$_className copyWith({');
    for (final field in _fieldList) {
      if (field.isRepeated) {
        out.println(
            ' List<${field.baseType.onlyDart(_prefixEntity)}>? ${field.memberNames!.fieldName},');
      } else {
        out.println(
            '${field.baseType.onlyDart(_prefixEntity)}? ${field.memberNames!.fieldName},');
      }
    }
    out.println('}) => $_className(');
    for (final field in _fieldList) {
      out.println(
          '${field.memberNames!.fieldName}: ${field.memberNames!.fieldName} ?? this.${field.memberNames!.fieldName},');
    }
    out.println(');');
    out.println();

    /// ToString
    out.println();
    out.println('@override');
    out.println('String toString() => \'$_className(\' + ');
    final toString = _fieldList
        .map((e) =>
            "'${e.memberNames!.fieldName}: \$${e.memberNames!.fieldName}'")
        .join(' + \n');
    out.println('$toString;');
    out.println();

    /// Props
    out.println();
    out.println('@override');
    out.println('List<Object?> get props => [');
    for (final field in _fieldList) {
      out.println('  ${field.memberNames!.fieldName},');
    }
    out.println('];');

    /// End class
    out.println();
    out.println('}');

    out.println();

    for (final m in _entityGenerators) {
      m.generate(out);
    }
  }

  void generateEnums(IndentingWriter out) {
    for (final e in _enumGenerators) {
      e.generate(out);
    }
  }
}
