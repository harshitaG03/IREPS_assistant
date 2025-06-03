import 'package:assistant/HistoryPage.dart';
import 'package:assistant/database_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AttachDocumentsPage extends StatefulWidget {
  final String queryId;

  AttachDocumentsPage({required this.queryId});

  @override
  _AttachDocumentsPageState createState() => _AttachDocumentsPageState();
}

class _AttachDocumentsPageState extends State<AttachDocumentsPage> {
  List<Map<String, dynamic>> documents = [];
  bool _isSubmitting = false;

  void addDocumentField() {
    setState(() {
      documents.add({
        'nameController': TextEditingController(),
        'descController': TextEditingController(),
        'file': null,
      });
    });
  }

  void pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      // Verify it's a PDF
      if (filePath.toLowerCase().endsWith('.pdf')) {
        setState(() {
          documents[index]['file'] = result.files.first;
        });
      } else {
        showErrorSnackbar("Please select a valid PDF file only.");
      }
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    addDocumentField(); // Initial field
  }

  @override
  void dispose() {
    // Clean up controllers when this widget is disposed
    for (var doc in documents) {
      doc['nameController'].dispose();
      doc['descController'].dispose();
    }
    super.dispose();
  }

  Future<void> saveDocuments() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      int savedCount = 0;
      final dbHelper = DatabaseHelper.instance;

      for (var doc in documents) {
        final file = doc['file'];
        final nameController = doc['nameController'] as TextEditingController;
        final descController = doc['descController'] as TextEditingController;

        if (file != null && file.path.endsWith('.pdf')) {
          // Copy the file to app's documents directory for permanent storage
          final fileName = file.name;
          final filePath = file.path;

          // Save to database
          await dbHelper.insertDocument(
            widget.queryId,
            nameController.text.isNotEmpty
                ? nameController.text.trim()
                : "Document ${documents.indexOf(doc) + 1}",
            descController.text.trim(),
            filePath, // Store the full path to the PDF file
          );

          savedCount++;
        }
      }

      setState(() {
        _isSubmitting = false;
      });

      if (savedCount > 0) {
        showSuccessSnackbar("$savedCount documents saved successfully");
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text("Success"),
            content: Text("$savedCount documents attached successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog

                  // Navigate to History Page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryPage()),
                  );
                },
                child: Text("Go to History"),
              ),
            ],
          ),
        );
      } else {
        showErrorSnackbar("No valid documents to save");
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print("Error saving documents: $e");
      showErrorSnackbar("Error saving documents: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          "Attach Documents",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Query ID: ${widget.queryId}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Document ${index + 1}",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (index > 0)
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          documents.removeAt(index);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      documents[index]['file'] != null
                                          ? Colors.green
                                          : Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => pickFile(index),
                                icon: Icon(
                                    documents[index]['file'] != null
                                        ? Icons.check_circle
                                        : Icons.attach_file,
                                    color: Colors.white),
                                label: Text(documents[index]['file'] != null
                                    ? "Change PDF"
                                    : "Select PDF"),
                              ),
                              if (documents[index]['file'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border:
                                          Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "${documents[index]['file'].name}",
                                            style: TextStyle(
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(height: 10),
                              TextField(
                                controller: documents[index]['descController'],
                                decoration: InputDecoration(
                                  labelText: "Description",
                                  hintText: "Enter document description",
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                style: TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : addDocumentField,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text("Add More"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasValidDocuments()
                            ? Colors.green[700]
                            : Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting || !_hasValidDocuments()
                          ? null
                          : saveDocuments,
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text("Save Documents"),
                    ),
                  ],
                )
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasValidDocuments() {
    for (var doc in documents) {
      if (doc['file'] != null && doc['file'].path.endsWith('.pdf')) {
        return true;
      }
    }
    return false;
  }
}
