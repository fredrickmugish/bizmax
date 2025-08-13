// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 2;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      category: fields[3] as String?,
      unit: fields[4] as String,
      buyingPrice: fields[5] as double,
      wholesalePrice: fields[6] as double?,
      retailPrice: fields[7] as double?,
      sellingPrice: fields[8] as double,
      unitDimensions: fields[9] as String?,
      unitQuantity: fields[10] as double,
      currentStock: fields[11] as int,
      minimumStock: fields[12] as int,
      isActive: fields[13] as bool,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      productImage: fields[16] as String?,
      isDirty: fields[17] as bool,
      isDeleted: fields[18] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.buyingPrice)
      ..writeByte(6)
      ..write(obj.wholesalePrice)
      ..writeByte(7)
      ..write(obj.retailPrice)
      ..writeByte(8)
      ..write(obj.sellingPrice)
      ..writeByte(9)
      ..write(obj.unitDimensions)
      ..writeByte(10)
      ..write(obj.unitQuantity)
      ..writeByte(11)
      ..write(obj.currentStock)
      ..writeByte(12)
      ..write(obj.minimumStock)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.productImage)
      ..writeByte(17)
      ..write(obj.isDirty)
      ..writeByte(18)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
