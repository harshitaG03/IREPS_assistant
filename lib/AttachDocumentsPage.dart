import './HistoryPage.dart';
import './chatbot_UI.dart';
import './database_helper.dart';
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

    if (result != null) {
      setState(() {
        documents[index]['file'] = result.files.first;
      });
    } else {
      // User canceled the picker or picked an invalid file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a PDF file only."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    addDocumentField(); // Initial field
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "Query ID: ${widget.queryId}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
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
                          Text("Document ${index + 1}",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              )),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => pickFile(index),
                            icon: Icon(Icons.attach_file, color: Colors.white),
                            label: Text("Attach Document"),
                          ),
                          if (documents[index]['file'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Selected: ${documents[index]['file'].name}",
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          TextField(
                            controller: documents[index]['nameController'],
                            decoration: InputDecoration(
                              hintText: "Enter Document description",
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              hintStyle: TextStyle(color: Colors.grey[600]),
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
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: addDocumentField,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Add More"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final dbHelper = DatabaseHelper.instance;
                    bool hasValidDocuments = false;

                    for (var doc in documents) {
                      final file = doc['file'];
                      final nameController =
                          doc['nameController'] as TextEditingController;

                      if (file != null && file.path.endsWith('.pdf')) {
                        // Get current date and time
                        final now = DateTime.now();
                        final dateAttached =
                            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

                        await dbHelper.insertDocument(
                          widget.queryId,
                          nameController.text.isNotEmpty
                              ? nameController.text.trim()
                              : "Document ${documents.indexOf(doc) + 1}",
                          "", // description is empty since we only have one text field now
                          file.name,
                        );

                        hasValidDocuments = true;
                      }
                    }

                    if (!hasValidDocuments) {
                      // Show error if no valid documents were attached
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Please attach at least one PDF document."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      documents.clear();
                      addDocumentField(); // reset to one field
                    });

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Success"),
                        content: Text("Documents attached successfully"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // close dialog
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => HistoryPage()),
                              );
                            },
                            child: Text("Go to History"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text("Submit"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
