import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chatbot.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 1, onCreate: _createDB, onConfigure: _onConfigure);
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
      has_ireps_account TEXT,
      email TEXT,
      mobile TEXT,
      department TEXT,
      firm_name TEXT,
      user_name TEXT,
      organization TEXT,
      zone TEXT,
      unit TEXT,
      designation TEXT,
      query_id TEXT,
      query_type TEXT,
      subject TEXT,
      query_description TEXT,
      created_at TEXT
      )
    ''');

    // Create vendor details table
    await db.execute('''
      CREATE TABLE vendor_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        firm_name TEXT,
        user_name TEXT,
        mobile TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS messages(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      query_id TEXT,
      sender TEXT,  // 'user' or 'bot'
      content TEXT,
      created_at TEXT,
      FOREIGN KEY(query_id) REFERENCES responses(query_id)
    )
  ''');

    // Create railway user details table
    await db.execute('''
      CREATE TABLE railway_user_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        organization TEXT,
        zone TEXT,
        unit TEXT,
        designation TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
    CREATE TABLE document_attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      query_id TEXT,
      document_name TEXT,
      document_description TEXT,
      file_path TEXT,
      date_attached TEXT
    )
    ''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_id TEXT,
    message TEXT,
    is_bot INTEGER,
    timestamp TEXT
  )
''');

    // Create queries table
    await db.execute('''
      CREATE TABLE queries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        query_id TEXT,
        query_type TEXT,
        subject TEXT,
        query_description TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        queryId TEXT,
        name TEXT,
        description TEXT,
        fileName TEXT,
        FOREIGN KEY (queryId) REFERENCES queries (id) ON DELETE CASCADE
      )
    ''');
  }

  // General query method to run custom queries
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForQuery(String queryId) async {
    Database db = await instance.database;
    return await db.query(
      'messages',
      where: 'query_id = ?',
      whereArgs: [queryId],
      orderBy: 'timestamp ASC',
    );
  }

  // Future<int> insertMessage(String queryId, String message, bool isBot) async {
  //   Database db = await instance.database;
  //   return await db.insert(
  //     'messages',
  //     {
  //       'query_id': queryId,
  //       'message': message,
  //       'is_bot': isBot ? 1 : 0,
  //       'timestamp': DateTime.now().toIso8601String(),
  //     },
  //   );
  // }
  // Combined insertMessage method
  Future<int> insertMessage(String queryId, String message, bool isBot) async {
    Database db = await instance.database;
    return await db.insert(
      'messages',
      {
        'query_id': queryId,
        'message': message,
        'is_bot': isBot ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Enhanced insertResponse method with timestamp
  Future<void> insertResponse(Map<String, dynamic> response) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    // Start a transaction to ensure data integrity
    await db.transaction((txn) async {
      // Add timestamp to the response
      response['created_at'] = now;

      // Check if user with email already exists
      List<Map<String, dynamic>> existingUsers = await txn
          .query('users', where: 'email = ?', whereArgs: [response['email']]);

      int userId;

      if (existingUsers.isEmpty) {
        // Insert new user
        userId = await txn.insert(
          'users',
          {
            'has_ireps_account': response['has_ireps_account'],
            'email': response['email'],
            'mobile': response['mobile'],
            'department': response['department'],
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Use existing user ID and update info
        userId = existingUsers.first['id'];
        await txn.update(
          'users',
          {
            'has_ireps_account': 'true', // Set to true since now they have an account
            'mobile': response['mobile'],
            'department': response['department'],
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
      }

      // Insert vendor details if applicable
      if (response['department'] == 'Vendor/Contractor/Auction Bidder') {
        // Check if vendor details already exist
        List<Map<String, dynamic>> existingVendor = await txn
            .query('vendor_details', where: 'user_id = ?', whereArgs: [userId]);

        if (existingVendor.isEmpty) {
          await txn.insert(
            'vendor_details',
            {
              'user_id': userId,
              'firm_name': response['firm_name'],
              'user_name': response['user_name'],
              'mobile': response['mobile'],
              'created_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.update(
            'vendor_details',
            {
              'firm_name': response['firm_name'],
              'user_name': response['user_name'],
              'mobile': response['mobile'],
              'updated_at': now,
            },
            where: 'user_id = ?',
            whereArgs: [userId],
          );
        }
      }

      if (response['department'] == 'Railway/Departmental User') {
        // Check if railway details already exist
        List<Map<String, dynamic>> existingRailway = await txn.query(
          'railway_user_details',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        if (existingRailway.isEmpty) {
          await txn.insert(
            'railway_user_details',
            {
              'user_id': userId,
              'organization': response['organization'],
              'zone': response['zone'],
              'unit': response['unit'],
              'designation': response['designation'],
              'created_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.update(
            'railway_user_details',
            {
              'organization': response['organization'],
              'zone': response['zone'],
              'unit': response['unit'],
              'designation': response['designation'],
              'updated_at': now,
            },
            where: 'user_id = ?',
            whereArgs: [userId],
          );
        }
      }

      // Insert query details with timestamp
      await txn.insert(
        'queries',
        {
          'user_id': userId,
          'query_id': response['query_id'],
          'query_type': response['query_type'],
          'subject': response['subject'],
          'query_description': response['query_description'],
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
  Future<void> insertQuery(Map<String, dynamic> queryData) async {
    final db = await instance.database;
    await db.insert('queries', queryData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertDocument(
      String queryId, String name, String description, String fileName) async {
    final db = await instance.database;

    // Get current date and time in string format
    final now = DateTime.now();
    final dateAttached =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    await db.insert('document_attachments', {
      'query_id': queryId,
      'document_name': name,
      'document_description': description,
      'file_path': fileName,
      'date_attached': dateAttached,
    });
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  // Future<void> insertResponse(Map<String, dynamic> response) async {
  //   final db = await instance.database;
  //
  //   // Start a transaction to ensure data integrity
  //   await db.transaction((txn) async {
  //     // Check if user with email already exists
  //     List<Map<String, dynamic>> existingUsers = await txn
  //         .query('users', where: 'email = ?', whereArgs: [response['email']]);
  //
  //     int userId;
  //
  //     if (existingUsers.isEmpty) {
  //       // Insert new user
  //       userId = await txn.insert(
  //           'users',
  //           {
  //             'has_ireps_account': response['has_ireps_account'],
  //             'email': response['email'],
  //             'mobile': response['mobile'],
  //             'department': response['department']
  //           },
  //           conflictAlgorithm: ConflictAlgorithm.replace);
  //     } else {
  //       // Use existing user ID and update info
  //       userId = existingUsers.first['id'];
  //       await txn.update(
  //           'users',
  //           {
  //             'has_ireps_account':
  //                 'true', // Set to true since now they have an account
  //             'mobile': response['mobile'],
  //             'department': response['department']
  //           },
  //           where: 'id = ?',
  //           whereArgs: [userId]);
  //     }
  //
  //     // Insert vendor details if applicable
  //     if (response['department'] == 'Vendor/Contractor/Auction Bidder') {
  //       // Check if vendor details already exist
  //       List<Map<String, dynamic>> existingVendor = await txn
  //           .query('vendor_details', where: 'user_id = ?', whereArgs: [userId]);
  //
  //       if (existingVendor.isEmpty) {
  //         await txn.insert(
  //             'vendor_details',
  //             {
  //               'user_id': userId,
  //               'firm_name': response['firm_name'],
  //               'user_name': response['user_name'],
  //               'mobile': response['mobile']
  //             },
  //             conflictAlgorithm: ConflictAlgorithm.replace);
  //       } else {
  //         await txn.update(
  //             'vendor_details',
  //             {
  //               'firm_name': response['firm_name'],
  //               'user_name': response['user_name'],
  //               'mobile': response['mobile']
  //             },
  //             where: 'user_id = ?',
  //             whereArgs: [userId]);
  //       }
  //     }
  //
  //     if (response['department'] == 'Railway/Departmental User') {
  //       // Check if railway details already exist
  //       List<Map<String, dynamic>> existingRailway = await txn.query(
  //           'railway_user_details',
  //           where: 'user_id = ?',
  //           whereArgs: [userId]);
  //
  //       if (existingRailway.isEmpty) {
  //         await txn.insert(
  //             'railway_user_details',
  //             {
  //               'user_id': userId,
  //               'organization': response['organization'],
  //               'zone': response['zone'],
  //               'unit': response['unit'],
  //               'designation': response['designation'] // Ensure designation is included
  //             },
  //             conflictAlgorithm: ConflictAlgorithm.replace);
  //       } else {
  //         await txn.update(
  //             'railway_user_details',
  //             {
  //               'organization': response['organization'],
  //               'zone': response['zone'],
  //               'unit': response['unit'],
  //               'designation': response['designation'] // Ensure designation is included
  //             },
  //             where: 'user_id = ?',
  //             whereArgs: [userId]);
  //       }
  //     }
  //     // Insert query details
  //     await txn.insert(
  //         'queries',
  //         {
  //           'user_id': userId,
  //           'query_id': response['query_id'],
  //           'query_type': response['query_type'],
  //           'subject': response['subject'],
  //           'query_description': response['query_description']
  //         },
  //         conflictAlgorithm: ConflictAlgorithm.replace);
  //   });
  // }

  // Method to retrieve user details by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    List<Map<String, dynamic>> results =
        await db.query('users', where: 'email = ?', whereArgs: [email]);

    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getDocumentsByQueryId(
      String queryId) async {
    final db = await database;
    return await db.query(
      'documents',
      where: 'query_id = ?',
      whereArgs: [queryId],
    );
  }

  // Method to retrieve query details by query ID
  Future<Map<String, dynamic>> getQueryById(String queryId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'queries',
      where: 'query_id = ?',
      whereArgs: [queryId],
    );
    return result.isNotEmpty ? result.first : {};
  }
}
