part of '../protoc.dart';

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

  final List<int> _fieldPathSegment;
  final DescriptorProto _descriptor;
  final List<EntityGenerator> _entityGenerators = <EntityGenerator>[];

  final List<List<ProtobufField>> _oneofFields;
  late List<OneofNames> _oneofNames;

  late List<ProtobufField> _fieldList;
  bool _resolved = false;

  bool _hasImport = false;

  EntityGenerator._(
    DescriptorProto descriptor,
    this.parent,
    int repeatedFieldIndex,
    int fieldIdTag,
  )   : _descriptor = descriptor,
        classname = '${messageOrEnumClassName(
          descriptor.name,
          {},
          parent: parent?.classname ?? '',
        )}$_prefixEntity',
        fullName = parent!.fullName == ''
            ? descriptor.name
            : '${parent.fullName}.${descriptor.name}',
        _fieldPathSegment = [fieldIdTag, repeatedFieldIndex],
        _oneofFields =
            List.generate(countRealOneofs(descriptor), (int index) => []) {
    for (var i = 0; i < _descriptor.nestedType.length; i++) {
      final n = _descriptor.nestedType[i];
      _entityGenerators.add(EntityGenerator.nested(n, this, i));
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
      if (field.descriptor.hasOneofIndex() &&
          !field.descriptor.proto3Optional) {
        _oneofFields[field.descriptor.oneofIndex].add(field);
      }
      _fieldList.add(field);
    }
    _oneofNames = members.oneofNames;

    for (final m in _entityGenerators) {
      m.resolve(ctx);
    }
  }

  void generate(IndentingWriter out) {
    if (!_hasImport) {
      /// Imports
      out.println('import \'package:equatable/equatable.dart\';');
      _hasImport = true;
    }

    /// Start class
    out.println('final class $classname extends Equatable  {');

    /// Contsructor
    out.println();
    out.println('const $classname({');
    for (final field in _fieldList) {
      out.println('required this.${field.memberNames!.fieldName},');
    }
    out.println('});');
    out.println();

    /// Final fields
    for (final field in _fieldList) {
      out.println(
          'final ${field.baseType.onlyDart(_prefixEntity)} ${field.memberNames!.fieldName};');
    }
    out.println();

    out.println('$classname copyWith({');
    for (final field in _fieldList) {
      if (field.isRepeated) {
        out.println(
            '${field.baseType.onlyDart(_prefixEntity)}? ${field.memberNames!.fieldName},');
      } else {
        out.println(
            '${field.baseType.onlyDart(_prefixEntity)}? ${field.memberNames!.fieldName},');
      }
    }
    out.println('}) => $classname(');
    for (final field in _fieldList) {
      if (field.isRepeated) {
        out.println(
            '${field.memberNames!.fieldName}: ${field.memberNames!.fieldName} ?? this.${field.memberNames!.fieldName},');
      } else {
        out.println(
            '${field.memberNames!.fieldName}: ${field.memberNames!.fieldName} ?? this.${field.memberNames!.fieldName},');
      }
    }
    out.println(');');
    out.println();

    /// ToString
    out.println();
    out.println('@override');
    out.println('String toString() => \'$classname(\' + ');
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
  }
}
