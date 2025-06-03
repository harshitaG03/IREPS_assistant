import 'dart:io';
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
    await db.execute('''
  CREATE TABLE user_responses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_id TEXT UNIQUE,
    email TEXT,
    mobile TEXT,
    department TEXT,
    firm_name TEXT,
    user_name TEXT,
    organization TEXT,
    zone TEXT,
    unit TEXT,
    designation TEXT,
    query_type TEXT,
    subject TEXT,
    query_description TEXT,
    attached_documents TEXT,
    reply_message TEXT,
    reply_date TEXT,
    created_at TEXT NOT NULL
  )
''');
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
      if (dateTimeStr.contains('T') || dateTimeStr.contains('Z')) {
        parsed = DateTime.parse(dateTimeStr);
      } else if (dateTimeStr.contains('-')) {
        parsed = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeStr);
      } else {
        parsed = DateFormat("dd-MM-yyyy HH:mm").parse(dateTimeStr);
      }
      return DateFormat('dd-MM-yyyy HH:mm').format(parsed);
    } catch (e) {
      print("Error parsing date: $e");
      return "No date available";
    }
  }

  Future<void> updateQueryDocuments(
      String queryId, List<String> documentPaths) async {
    final db = await instance.database;
    try {
      String documentsText = documentPaths.join(', ');
      await db.update(
        'user_responses',
        {'attached_documents': documentsText},
        where: 'query_id = ?',
        whereArgs: [queryId],
      );
      print('Documents updated for query: $queryId');
    } catch (e) {
      print('Error updating documents: $e');
    }
  }

  Future<void> insertUserResponse(Map<String, dynamic> responseData) async {
    final db = await instance.database;
    responseData['created_at'] = _getCurrentDateTime();
    responseData['reply_date'] = _getCurrentDateTime();
    try {
      // Check if a response with this query_id already exists
      List<Map<String, dynamic>> existingResponses = await db.query(
        'user_responses',
        where: 'query_id = ?',
        whereArgs: [responseData['query_id']],
      );
      if (existingResponses.isEmpty) {
        // Insert new response
        await db.insert('user_responses', responseData,
            conflictAlgorithm: ConflictAlgorithm.replace);
        print(
            'User response inserted successfully: ${responseData['query_id']}');
      } else {
        // Update existing response
        await db.update(
          'user_responses',
          responseData,
          where: 'query_id = ?',
          whereArgs: [responseData['query_id']],
        );
        print(
            'User response updated successfully: ${responseData['query_id']}');
      }
    } catch (e) {
      print('Error inserting user response: $e');
    }
  }

  Future<bool> documentExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('Error checking document existence: $e');
      return false;
    }
  }

  Future<void> updateAttachedDocuments(
      String queryId, String documentsText) async {
    final db = await instance.database;

    try {
      await db.update(
        'user_responses',
        {'attached_documents': documentsText},
        where: 'query_id = ?',
        whereArgs: [queryId],
      );
      print('Attached documents updated for query: $queryId');
    } catch (e) {
      print('Error updating attached documents: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserResponseByQueryIdAndEmail(
      String queryId, String email) async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        'user_responses',
        where: 'query_id = ? AND email = ?',
        whereArgs: [queryId, email],
      );
      if (results.isNotEmpty) {
        return results.first;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user response: $e');
      return null;
    }
  }

  Future<void> insertQuery(Map<String, dynamic> queryData) async {
    final db = await instance.database;
    queryData['date_created'] = _getCurrentDateTime();
    try {
      List<Map<String, dynamic>> existingQueries = await db.query(
        'queries',
        where: 'query_id = ?',
        whereArgs: [queryData['query_id']],
      );
      if (existingQueries.isEmpty) {
        await db.insert('queries', queryData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
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
                'department': response['department']
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          userId = existingUsers.first['id'];
          await txn.update(
              'users',
              {
                'has_ireps_account':
                'true', // Set to true since now they have an account
                'mobile': response['mobile'],
                'department': response['department']
              },
              where: 'id = ?',
              whereArgs: [userId]);
        }
        if (response['department'] == 'Vendor/Contractor/Auction Bidder') {
          // Check if vendor details already exist
          List<Map<String, dynamic>> existingVendor = await txn.query(
              'vendor_details',
              where: 'user_id = ?',
              whereArgs: [userId]);
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
              whereArgs: [userId]);
          if (existingRailway.isEmpty) {
            await txn.insert(
                'railway_user_details',
                {
                  'user_id': userId,
                  'organization': response['organization'],
                  'zone': response['zone'],
                  'unit': response['unit'],
                  'designation':
                  response['designation'] // Ensure designation is included
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await txn.update(
                'railway_user_details',
                {
                  'organization': response['organization'],
                  'zone': response['zone'],
                  'unit': response['unit'],
                  'designation':
                  response['designation'] // Ensure designation is included
                },
                where: 'user_id = ?',
                whereArgs: [userId]);
          }
        }
        final dateCreated = _getCurrentDateTime();
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
                'date_created': dateCreated // Add the date_created field
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          await txn.update(
              'queries',
              {
                'query_type': response['query_type'],
                'subject': response['subject'],
                'query_description': response['query_description'],
                'date_created': dateCreated // Update the date_created field
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

  Future<List<Map<String, dynamic>>> getSupplementaryQuestions(
      String queryId) async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> questions = await db.query(
        'supplementary_questions',
        where: 'original_query_id = ?',
        whereArgs: [queryId],
        orderBy: 'created_at DESC',
      );
      print(
          'Found ${questions.length} supplementary questions for query $queryId');
      return questions;
    } catch (e) {
      print('Error getting supplementary questions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDetailedQueryStatus(
      String queryId, String email) async {
    final db = await instance.database;
    try {
      // Get main query response
      List<Map<String, dynamic>> queryResponse = await db.query(
        'user_responses',
        where: 'query_id = ? AND email = ?',
        whereArgs: [queryId, email],
      );

      if (queryResponse.isEmpty) {
        return null;
      }

      Map<String, dynamic> result = Map.from(queryResponse.first);

      // Get associated documents
      List<Map<String, dynamic>> documents =
      await getDocumentsByQueryId(queryId);
      result['documents'] = documents;

      // Get supplementary questions
      List<Map<String, dynamic>> suppQuestions =
      await getSupplementaryQuestions(queryId);
      result['supplementary_questions'] = suppQuestions;

      return result;
    } catch (e) {
      print('Error getting detailed query status: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentsByQueryId(
      String queryId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> docs = await db.query(
        'document_attachments',
        where: 'query_id = ?',
        whereArgs: [queryId],
      );
      if (docs.isEmpty) {
        docs = await db.query(
          'documents',
          where: 'queryId = ?',
          whereArgs: [queryId],
        );
      }
      print('Found ${docs.length} documents for query $queryId');
      return docs;
    } catch (e) {
      print('Error getting documents by query ID: $e');
      return [];
    }
  }

  Future<void> createSupplementaryQuestionsTable() async {
    final db = await instance.database;
    try {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS supplementary_questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_query_id TEXT,
      email TEXT,
      supplementary_question TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY(original_query_id) REFERENCES user_responses(query_id) ON DELETE CASCADE
    )
  ''');
      print('Supplementary questions table created/verified');
    } catch (e) {
      print('Error creating supplementary questions table: $e');
    }
  }

  Future<void> insertSupplementaryQuestion(
      Map<String, dynamic> questionData) async {
    final db = await instance.database;
    questionData['created_at'] = _getCurrentDateTime();
    try {
      await db.insert('supplementary_questions', questionData);
      print('Supplementary question inserted successfully');
    } catch (e) {
      print('Error inserting supplementary question: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getQueriesByEmail(String email) async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> queries = await db.query(
        'user_responses',
        where: 'email = ?',
        whereArgs: [email],
        orderBy: 'created_at DESC',
      );

      // Get documents for each query
      for (var query in queries) {
        List<Map<String, dynamic>> docs =
        await getDocumentsByQueryId(query['query_id']);
        query['documents'] = docs;
      }

      return queries;
    } catch (e) {
      print('Error getting queries by email: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQueryStatusByIdAndEmail(
      String queryId, String email) async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        'user_responses',
        where: 'query_id = ? AND email = ?',
        whereArgs: [queryId, email],
      );
      if (results.isNotEmpty) {
        return results.first;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting query status: $e');
      return null;
    }
  }

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

  Future<Map<String, int>> checkDatabaseIntegrity() async {
    final db = await database;
    Map<String, int> tableCounts = {};
    try {
      List<Map<String, dynamic>> tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");
      for (var table in tables) {
        String tableName = table['name'];
        List<Map<String, dynamic>> count =
        await db.rawQuery('SELECT COUNT(*) as count FROM "$tableName"');
        tableCounts[tableName] = count.first['count'];
      }
      print('Database integrity check: $tableCounts');
      return tableCounts;
    } catch (e) {
      print('Error checking database integrity: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    final db = await database;
    try {
      return await db.query('document_attachments');
    } catch (e) {
      print('Error getting all documents: $e');
      return [];
    }
  }

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
