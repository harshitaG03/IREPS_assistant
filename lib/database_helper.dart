import 'package:intl/intl.dart';
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
        query_id TEXT,
        query_type TEXT,
        subject TEXT,
        query_description TEXT,
        date_submitted TEXT
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

    // Create document attachments table
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

    // Create queries table with date_created field
    await db.execute(''' 
      CREATE TABLE queries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        query_id TEXT UNIQUE,
        query_type TEXT,
        subject TEXT,
        query_description TEXT,
        date_created TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Adding UNIQUE constraint to query_id to avoid duplicates

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        queryId TEXT,
        name TEXT,
        description TEXT,
        fileName TEXT,
        FOREIGN KEY (queryId) REFERENCES queries (query_id) ON DELETE CASCADE
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

    try {
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
    } catch (e) {
      print('Error executing query on $table: $e');
      return [];
    }
  }

  String _getCurrentDateTime() {
    // Store date in ISO8601 format for better compatibility and sorting
    return DateTime.now().toIso8601String();
  }

  static String formatDateTimeForDisplay(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "No date available";
    try {
      DateTime parsed;
      // Handle ISO8601 format (from database)
      if (dateTimeStr.contains('T') || dateTimeStr.contains('Z')) {
        parsed = DateTime.parse(dateTimeStr);
      }
      // Handle your custom format (yyyy-MM-dd HH:mm)
      else if (dateTimeStr.contains('-')) {
        parsed = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeStr);
      }
      // Fallback for dd-MM-yyyy format
      else {
        parsed = DateFormat("dd-MM-yyyy HH:mm").parse(dateTimeStr);
      }
      // Format in user-friendly format
      return DateFormat('dd-MM-yyyy HH:mm').format(parsed);
    } catch (e) {
      print("Error parsing date: $e");
      return "No date available";
    }
  }

  Future<void> insertQuery(Map<String, dynamic> queryData) async {
    final db = await instance.database;

    // Store date in ISO8601 format
    queryData['date_created'] = _getCurrentDateTime();

    try {
      // First check if a query with this ID already exists
      List<Map<String, dynamic>> existingQueries = await db.query(
        'queries',
        where: 'query_id = ?',
        whereArgs: [queryData['query_id']],
      );

      if (existingQueries.isEmpty) {
        // Insert new query
        await db.insert('queries', queryData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        // Update existing query
        await db.update(
          'queries',
          queryData,
          where: 'query_id = ?',
          whereArgs: [queryData['query_id']],
        );
      }
      print('Query inserted/updated successfully: ${queryData['query_id']}');
    } catch (e) {
      print('Error inserting query: $e');
    }
  }

  Future<void> insertDocument(
      String queryId, String name, String description, String fileName) async {
    final db = await instance.database;

    // Get current date and time in string format
    final dateAttached = _getCurrentDateTime();

    try {
      await db.insert('document_attachments', {
        'query_id': queryId,
        'document_name': name,
        'document_description': description,
        'file_path': fileName,
        'date_attached': dateAttached,
      });
      print('Document inserted successfully for query: $queryId');
    } catch (e) {
      print('Error inserting document: $e');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    try {
      int id = await db.insert(table, values);
      print('Data inserted into $table with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting into $table: $e');
      return -1;
    }
  }

  Future<void> insertResponse(Map<String, dynamic> response) async {
    final db = await instance.database;

    try {
      // Start a transaction to ensure data integrity
      await db.transaction((txn) async {
        // Check if user with email already exists
        List<Map<String, dynamic>> existingUsers = await txn.query(
            'users',
            where: 'email = ?',
            whereArgs: [response['email']]
        );

        int userId;

        if (existingUsers.isEmpty) {
          // Insert new user
          userId = await txn.insert(
              'users',
              {
                'has_ireps_account': response['has_ireps_account'],
                'email': response['email'],
                'mobile': response['mobile'],
                'department': response['department']
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          // Use existing user ID and update info
          userId = existingUsers.first['id'];
          await txn.update(
              'users',
              {
                'has_ireps_account': 'true', // Set to true since now they have an account
                'mobile': response['mobile'],
                'department': response['department']
              },
              where: 'id = ?',
              whereArgs: [userId]);
        }

        // Insert vendor details if applicable
        if (response['department'] == 'Vendor/Contractor/Auction Bidder') {
          // Check if vendor details already exist
          List<Map<String, dynamic>> existingVendor = await txn.query(
              'vendor_details',
              where: 'user_id = ?',
              whereArgs: [userId]
          );

          if (existingVendor.isEmpty) {
            await txn.insert(
                'vendor_details',
                {
                  'user_id': userId,
                  'firm_name': response['firm_name'],
                  'user_name': response['user_name'],
                  'mobile': response['mobile']
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await txn.update(
                'vendor_details',
                {
                  'firm_name': response['firm_name'],
                  'user_name': response['user_name'],
                  'mobile': response['mobile']
                },
                where: 'user_id = ?',
                whereArgs: [userId]);
          }
        }

        if (response['department'] == 'Railway/Departmental User') {
          // Check if railway details already exist
          List<Map<String, dynamic>> existingRailway = await txn.query(
              'railway_user_details',
              where: 'user_id = ?',
              whereArgs: [userId]
          );

          if (existingRailway.isEmpty) {
            await txn.insert(
                'railway_user_details',
                {
                  'user_id': userId,
                  'organization': response['organization'],
                  'zone': response['zone'],
                  'unit': response['unit'],
                  'designation': response['designation'] // Ensure designation is included
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await txn.update(
                'railway_user_details',
                {
                  'organization': response['organization'],
                  'zone': response['zone'],
                  'unit': response['unit'],
                  'designation': response['designation'] // Ensure designation is included
                },
                where: 'user_id = ?',
                whereArgs: [userId]);
          }
        }

        // Insert query details with date_created field
        final dateCreated = _getCurrentDateTime();

        // Check if query already exists
        List<Map<String, dynamic>> existingQueries = await txn.query(
          'queries',
          where: 'query_id = ?',
          whereArgs: [response['query_id']],
        );

        if (existingQueries.isEmpty) {
          await txn.insert(
              'queries',
              {
                'user_id': userId,
                'query_id': response['query_id'],
                'query_type': response['query_type'],
                'subject': response['subject'],
                'query_description': response['query_description'],
                'date_created': dateCreated  // Add the date_created field
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          await txn.update(
              'queries',
              {
                'query_type': response['query_type'],
                'subject': response['subject'],
                'query_description': response['query_description'],
                'date_created': dateCreated  // Update the date_created field
              },
              where: 'query_id = ?',
              whereArgs: [response['query_id']]);
        }
      });

      print('Response inserted successfully: ${response['query_id']}');
    } catch (e) {
      print('Error inserting response: $e');
    }
  }

  // Method to retrieve user details by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> results =
      await db.query('users', where: 'email = ?', whereArgs: [email]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentsByQueryId(String queryId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> docs = await db.query(
        'document_attachments',  // Changed from 'documents' to 'document_attachments'
        where: 'query_id = ?',   // Changed from 'query_id' to 'query_id'
        whereArgs: [queryId],
      );
      print('Found ${docs.length} documents for query $queryId');
      return docs;
    } catch (e) {
      print('Error getting documents by query ID: $e');
      return [];
    }
  }

  // Improved method to retrieve query details by query ID
  Future<Map<String, dynamic>> getQueryById(String queryId) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> result = await db.query(
        'queries',
        where: 'query_id = ?',
        whereArgs: [queryId],
      );

      if (result.isNotEmpty) {
        print('Query found: ${result.first}');
        return result.first;
      } else {
        print('No query found with ID: $queryId');
        return {};
      }
    } catch (e) {
      print('Error fetching query by ID: $e');
      return {};
    }
  }

  // Method to check database integrity
  Future<Map<String, int>> checkDatabaseIntegrity() async {
    final db = await database;
    Map<String, int> tableCounts = {};

    try {
      // Get list of all tables
      List<Map<String, dynamic>> tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
      );

      // Count records in each table
      for (var table in tables) {
        String tableName = table['name'];
        List<Map<String, dynamic>> count = await db.rawQuery('SELECT COUNT(*) as count FROM "$tableName"');
        tableCounts[tableName] = count.first['count'];
      }

      print('Database integrity check: $tableCounts');
      return tableCounts;
    } catch (e) {
      print('Error checking database integrity: $e');
      return {};
    }
  }

  // Method to debug document_attachments table
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    final db = await database;
    try {
      return await db.query('document_attachments');
    } catch (e) {
      print('Error getting all documents: $e');
      return [];
    }
  }

  // Method to debug queries table
  Future<List<Map<String, dynamic>>> getAllQueries() async {
    final db = await database;
    try {
      return await db.query('queries');
    } catch (e) {
      print('Error getting all queries: $e');
      return [];
    }
  }
}