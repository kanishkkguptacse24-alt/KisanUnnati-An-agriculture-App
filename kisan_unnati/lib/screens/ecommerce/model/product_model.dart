import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  double? highestBid;
  final String unit;
  final String sellerName;
  double stockQuantity;
  final String? imagePath;
  final String address;
  final String sellerRole;
  final String listingType;
  final bool isBiddable;
  final DateTime? biddingEndDate;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.highestBid,
    required this.unit,
    required this.sellerName,
    required this.stockQuantity,
    this.imagePath,
    required this.address,
    required this.sellerRole,
    required this.listingType,
    required this.isBiddable,
    this.biddingEndDate,
  });

  // 🔥 1. PACK DATA FOR FIREBASE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'highestBid': highestBid,
      'unit': unit,
      'sellerName': sellerName,
      'stockQuantity': stockQuantity,
      'imagePath': imagePath,
      'address': address,
      'sellerRole': sellerRole,
      'listingType': listingType,
      'isBiddable': isBiddable,
      'biddingEndDate': biddingEndDate != null ? Timestamp.fromDate(biddingEndDate!) : null,
    };
  }

  // 🔥 2. UNPACK DATA FROM FIREBASE
  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      highestBid: map['highestBid'] != null ? (map['highestBid']).toDouble() : null,
      unit: map['unit'] ?? '',
      sellerName: map['sellerName'] ?? '',
      stockQuantity: (map['stockQuantity'] ?? 0.0).toDouble(),
      imagePath: map['imagePath'],
      address: map['address'] ?? '',
      sellerRole: map['sellerRole'] ?? '',
      listingType: map['listingType'] ?? 'Sell',
      isBiddable: map['isBiddable'] ?? false,
      biddingEndDate: map['biddingEndDate'] != null ? (map['biddingEndDate'] as Timestamp).toDate() : null,
    );
  }
}

