import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'AttachDocumentsPage.dart';
import 'database_helper.dart';
import 'chatbot_UI.dart';

import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> queryHistory = [];
  Map<String, Map<String, dynamic>> userDetails = {};
  Map<String, Map<String, dynamic>> vendorDetails = {};
  Map<String, Map<String, dynamic>> railwayDetails = {};
  Map<String, List<Map<String, dynamic>>> documents = {};
  bool isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredHistory = [];
  DateTime? mostRecentUpdate; // To track the most recent update time

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });
    final queries = await dbHelper.query('queries', orderBy: 'id DESC');
    Map<String, Map<String, dynamic>> usersMap = {};
    Map<String, Map<String, dynamic>> vendorsMap = {};
    Map<String, Map<String, dynamic>> railwayUsersMap = {};
    Map<String, List<Map<String, dynamic>>> docsMap = {};
    DateTime? mostRecent;
    // Fetch details for each query
    for (var query in queries) {
      final queryId = query['query_id'];
      final userId = query['user_id'];
      // Check if this query has a timestamp and update mostRecent if needed
      if (query['created_at'] != null) {
        try {
          final queryTime = DateTime.parse(query['created_at']);
          if (mostRecent == null || queryTime.isAfter(mostRecent)) {
            mostRecent = queryTime;
          }
        } catch (e) {
        }
      }
      // Get user details
      if (userId != null) {
        final userList = await dbHelper.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (userList.isNotEmpty) {
          usersMap[queryId] = userList.first;
          // Get vendor details if applicable
          if (userList.first['department'] ==
              'Vendor/Contractor/Auction Bidder') {
            final vendorList = await dbHelper.query(
              'vendor_details',
              where: 'user_id = ?',
              whereArgs: [userId],
            );
            if (vendorList.isNotEmpty) {
              vendorsMap[queryId] = vendorList.first;
            }
          }
          // Get railway user details if applicable
          if (userList.first['department'] == 'Railway/Departmental User') {
            final railwayList = await dbHelper.query(
              'railway_user_details',
              where: 'user_id = ?',
              whereArgs: [userId],
            );
            if (railwayList.isNotEmpty) {
              railwayUsersMap[queryId] = railwayList.first;
            }
          }
        }
      }
      // Get documents for this query
      final docs = await dbHelper.query(
        'document_attachments',
        where: 'query_id = ?',
        whereArgs: [queryId],
      );
      // Check if any document is more recent than current mostRecent
      for (var doc in docs) {
        if (doc['date_attached'] != null) {
          try {
            final docTime = DateTime.parse(doc['date_attached']);
            if (mostRecent == null || docTime.isAfter(mostRecent)) {
              mostRecent = docTime;
            }
          } catch (e) {
          }
        }
      }
      docsMap[queryId] = docs;
    }
    setState(() {
      queryHistory = queries;
      filteredHistory = queries; // default to full list
      userDetails = usersMap;
      vendorDetails = vendorsMap;
      railwayDetails = railwayUsersMap;
      documents = docsMap;
      mostRecentUpdate = mostRecent;
      isLoading = false;
    });
  }
  void _filterHistory(String input) {
    if (input.isEmpty) {
      setState(() => filteredHistory = queryHistory);
    } else {
      setState(() {
        filteredHistory = queryHistory
            .where((query) => query['query_id']
            .toString()
            .toLowerCase()
            .contains(input.toLowerCase()))
            .toList();
      });
    }
  }
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr; // Return original if parsing fails
    }
  }
  // Check if a given date string is within 24 hours of the most recent update
  bool _isRecentlyUpdated(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty || mostRecentUpdate == null) return false;
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      // Consider it recent if it's within 24 hours of the most recent update
      return mostRecentUpdate!.difference(dateTime).inHours < 24;
    } catch (e) {
      return false;
    }
  }
  // Check if this is the most recent query
  bool _isLatestQuery(int index) {
    return index == 0; // Since queries are ordered by ID DESC
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      appBar: AppBar(
        title: isSearching
            ? TextField(
          controller: searchController,
          onChanged: _filterHistory,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by Query ID',
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.black87, fontSize: 18),
        )
            : Text(
          "History",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  _filterHistory('');
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
              child: Text("No query history found",
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600])),
            )
                : ListView.builder(
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final query = filteredHistory[index];
                final queryId = query['query_id'];
                final user = userDetails[queryId];
                final vendor = vendorDetails[queryId];
                final railway = railwayDetails[queryId];
                final queryDocs = documents[queryId] ?? [];
                // Check if this is the latest query or has recently updated docs
                final isLatest = _isLatestQuery(index);
                bool hasRecentDocs = false;
                for (var doc in queryDocs) {
                  if (_isRecentlyUpdated(doc['date_attached'])) {
                    hasRecentDocs = true;
                    break;
                  }
                }
                return Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${index + 1}. Query ID: $queryId",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                )
                              ],
                            ),
                            if (user != null) ...[
                              Container(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DetailRow(
                                            title: "Email",
                                            value: user['email'] ?? 'N/A',
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: DetailRow(
                                            title: "IREPS Account",
                                            value: (user['has_ireps_account'] == 'true') ? 'Yes' : 'No',
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DetailRow(
                                            title: "Mobile",
                                            value: user['mobile'] ?? 'N/A',
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: DetailRow(
                                            title: "Type",
                                            value: query['query_type'] ?? 'N/A',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (vendor != null) ...[
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Vendor Details",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    DetailRow(
                                      title: "Firm Name",
                                      value:
                                      vendor['firm_name'] ?? 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                            if (railway != null) ...[
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Railway User Details",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              DetailRow(
                                                title: "Organization",
                                                value: railway[
                                                'organization'] ??
                                                    'N/A',
                                              ),
                                              DetailRow(
                                                title: "Designation",
                                                value: railway['designation'] ?? 'N/A',
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              DetailRow(
                                                title: "Unit",
                                                value:
                                                railway['unit'] ??
                                                    'N/A',
                                              ),
                                              DetailRow(
                                                title: "Zone",
                                                value:
                                                railway['zone'] ??
                                                    'N/A',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        queryDocs.isEmpty
                                            ? "No documents attached"
                                            : "Attached Documents",
                                        style: TextStyle(
                                          fontStyle:
                                          queryDocs.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          color: Colors.grey[600],
                                          fontWeight:
                                          queryDocs.isEmpty ? FontWeight.normal : FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green[800],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AttachDocumentsPage(queryId: queryId),
                                            ),
                                          ).then((_) => _loadHistory());
                                        },
                                        constraints: BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  if (queryDocs.isNotEmpty)
                                    Column(
                                      children: queryDocs.map((doc) {
                                        final isRecentDoc = _isRecentlyUpdated(doc['date_attached']);
                                        return Card(
                                          color: isRecentDoc ? Colors.green[50] : null,
                                          elevation: 1,
                                          margin: EdgeInsets.only(bottom: 6),
                                          child: Stack(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.description,
                                                        color: Colors.blue[700], size: 16),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            doc['document_name'] ?? 'Unnamed document',
                                                            style: TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          if (doc['document_description'] != null &&
                                                              doc['document_description'].isNotEmpty)
                                                            Text(
                                                              "Description: ${doc['document_description']}",
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                          Text(
                                                            "Attached: ${_formatDateTime(doc['date_attached'])}",
                                                            style: TextStyle(
                                                                color: Colors.grey[600], fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(Icons.file_download,
                                                              color: Colors.green[700], size: 20),
                                                          onPressed: () {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    "Opening document: ${doc['document_name']}"),
                                                              ),
                                                            );
                                                          },
                                                          constraints: BoxConstraints(),
                                                          padding: EdgeInsets.zero,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isRecentDoc)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding:
                                                    EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius: BorderRadius.only(
                                                        topRight: Radius.circular(4),
                                                        bottomLeft: Radius.circular(4),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'NEW',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            )

                          ],
                        ),
                      ),
                      // Latest query badge
                      if (isLatest)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'LATEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Recently updated badge for documents
                      if (hasRecentDocs && !isLatest)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'UPDATED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatbotApp()),
          );
        },
        child: Icon(Icons.chat_bubble_outline, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Helper widget for displaying detail rows
class DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final double fontSize;

  const DetailRow({
    required this.title,
    required this.value,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}