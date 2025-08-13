// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusinessRecordAdapter extends TypeAdapter<BusinessRecord> {
  @override
  final int typeId = 1;

  @override
  BusinessRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessRecord(
      id: fields[0] as String,
      type: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as double,
      date: fields[4] as DateTime,
      category: fields[5] as String?,
      notes: fields[6] as String?,
      customerName: fields[7] as String?,
      supplierName: fields[8] as String?,
      inventoryItemId: fields[9] as String?,
      quantity: fields[10] as int?,
      costOfGoodsSold: fields[11] as double?,
      fundingSource: fields[12] as String?,
      unitPrice: fields[13] as double,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      isCreditSale: fields[16] as bool,
      totalAmount: fields[17] as double?,
      amountPaid: fields[18] as double?,
      debtAmount: fields[19] as double?,
      user: (fields[20] as Map?)?.cast<String, dynamic>(),
      isDirty: fields[21] as bool,
      saleType: fields[22] as String?,
      transactionId: fields[23] as String?,
      isDeleted: fields[24] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, BusinessRecord obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.customerName)
      ..writeByte(8)
      ..write(obj.supplierName)
      ..writeByte(9)
      ..write(obj.inventoryItemId)
      ..writeByte(10)
      ..write(obj.quantity)
      ..writeByte(11)
      ..write(obj.costOfGoodsSold)
      ..writeByte(12)
      ..write(obj.fundingSource)
      ..writeByte(13)
      ..write(obj.unitPrice)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.isCreditSale)
      ..writeByte(17)
      ..write(obj.totalAmount)
      ..writeByte(18)
      ..write(obj.amountPaid)
      ..writeByte(19)
      ..write(obj.debtAmount)
      ..writeByte(20)
      ..write(obj.user)
      ..writeByte(21)
      ..write(obj.isDirty)
      ..writeByte(22)
      ..write(obj.saleType)
      ..writeByte(23)
      ..write(obj.transactionId)
      ..writeByte(24)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
