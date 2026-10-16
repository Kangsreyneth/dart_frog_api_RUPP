import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/db/mongo.dart';

/// Run once:  dart run bin/seed.dart
Future<void> main() async {
  final db = await Mongo.db;

  final categories = db.collection('categories');
  if (await categories.count() == 0) {
    final catNames = [
      'Lightsticks',
      'Photocards',
      'Albums',
      'Keychains & Charms',
      'Apparel',
      'Bags & Pouches',
    ];
    final ids = <String, String>{};
    for (final name in catNames) {
      final id = ObjectId();
      ids[name] = id.toHexString();
      await categories.insertOne({
        '_id': id,
        'name': name,
        'imageUrl': 'https://picsum.photos/seed/${name.hashCode}/300/300',
      });
    }

    final items = <List<Object>>[
      ['BTS Official Light Stick (ARMY Bomb)', 'Lightsticks', 'BTS', 54.0],
      ['BLACKPINK Hammer Light Stick', 'Lightsticks', 'BLACKPINK', 49.0],
      ['Stray Kids Light Stick', 'Lightsticks', 'Stray Kids', 45.0],
      ['NewJeans Bunny Light Stick', 'Lightsticks', 'NewJeans', 42.0],
      ['BTS Proof Photocard Set', 'Photocards', 'BTS', 8.5],
      ['TWICE Photocard Binder Set', 'Photocards', 'TWICE', 12.0],
      ['SEVENTEEN Photocard Pack', 'Photocards', 'SEVENTEEN', 7.5],
      ['BLACKPINK Born Pink Album', 'Albums', 'BLACKPINK', 28.0],
      ['Stray Kids ATE Album', 'Albums', 'Stray Kids', 24.0],
      ['aespa Armageddon Album', 'Albums', 'aespa', 26.0],
      ['BT21 Acrylic Keychain', 'Keychains & Charms', 'BTS', 6.0],
      ['SKZOO Plush Keyring', 'Keychains & Charms', 'Stray Kids', 9.0],
      ['TWICE Lovely Charm', 'Keychains & Charms', 'TWICE', 5.5],
      ['SEVENTEEN Tour Hoodie', 'Apparel', 'SEVENTEEN', 38.0],
      ['BLACKPINK Concert Tee', 'Apparel', 'BLACKPINK', 22.0],
      ['BTS Tote Bag', 'Bags & Pouches', 'BTS', 15.0],
      ['aespa Mini Pouch', 'Bags & Pouches', 'aespa', 11.0],
    ];

    var n = 0;
    for (final item in items) {
      n++;
      await db.collection('products').insertOne({
        '_id': ObjectId(),
        'name': item[0],
        'description':
            'Official-style ${item[1].toString().toLowerCase()} for ${item[2]} fans. Ships from Phnom Penh.',
        'price': item[3],
        'imageUrl': 'https://picsum.photos/seed/phsardrop$n/500/500',
        'categoryId': ids[item[1]],
        'group': item[2],
        'stock': 25,
        'createdAt': DateTime.now().toUtc().subtract(Duration(minutes: n)),
      });
    }
    print('Seeded ${catNames.length} categories and ${items.length} products');
  } else {
    print('Catalog already seeded, skipping');
  }

  final users = db.collection('users');
  if (await users.findOne(where.eq('email', 'admin@phsardrop.com')) == null) {
    await users.insertOne({
      '_id': ObjectId(),
      'name': 'Admin',
      'email': 'admin@phsardrop.com',
      'passwordHash': BCrypt.hashpw('Admin@123', BCrypt.gensalt()),
      'phone': '',
      'address': '',
      'role': 'admin',
      'createdAt': DateTime.now().toUtc(),
    });
    print('Created admin: admin@phsardrop.com / Admin@123 (change it!)');
  }
  await db.close();
}
