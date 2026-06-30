// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EbayListingAdapter extends TypeAdapter<EbayListing> {
  @override
  final int typeId = 0;

  @override
  EbayListing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EbayListing(
      itemId: fields[0] as String,
      title: fields[1] as String,
      price: fields[2] as double,
      currency: fields[3] as String,
      imageUrls: (fields[4] as List).cast<String>(),
      auctionEndTime: fields[5] as DateTime?,
      listingUrl: fields[6] as String,
      listingType: fields[7] as String,
      bidCount: fields[8] as int?,
      fetchedAt: fields[9] as DateTime,
      condition: fields[10] as String?,
      shippingCost: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EbayListing obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.imageUrls)
      ..writeByte(5)
      ..write(obj.auctionEndTime)
      ..writeByte(6)
      ..write(obj.listingUrl)
      ..writeByte(7)
      ..write(obj.listingType)
      ..writeByte(8)
      ..write(obj.bidCount)
      ..writeByte(9)
      ..write(obj.fetchedAt)
      ..writeByte(10)
      ..write(obj.condition)
      ..writeByte(11)
      ..write(obj.shippingCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EbayListingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
