import 'package:test/test.dart';

import '../out/descriptor.pb.dart';
import '../out/descriptor_entity.dart';

void main() {
  group('DescriptorProtoEntity', () {
    test('equals', () {
      final entity = DescriptorProtoEntity(
        name: 'name',
        field: [],
        nestedType: [],
        enumType: [],
        extensionRange: [],
        extension: [],
        oneofDecl: [],
        reservedRange: [],
        reservedName: [],
      );

      final pb = DescriptorProto(
        name: 'name',
        field: [],
        nestedType: [],
        enumType: [],
        extensionRange: [],
        extension: [],
        oneofDecl: [],
        reservedRange: [],
        reservedName: [],        
      );

      expect(entity.name, pb.name);
      expect(entity.field, pb.field);
      expect(entity.nestedType, pb.nestedType);
      expect(entity.enumType, pb.enumType);
      expect(entity.extensionRange, pb.extensionRange);
      expect(entity.extension, pb.extension);
      expect(entity.oneofDecl, pb.oneofDecl);
      expect(entity.reservedRange, pb.reservedRange);
      expect(entity.reservedName, pb.reservedName);
    });
  });
}
