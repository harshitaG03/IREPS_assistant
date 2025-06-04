import 'dart:core';
import 'dart:math';
import 'package:open_file/open_file.dart';

import './AttachDocumentsPage.dart';
import './HistoryPage.dart';
import './slide_page_route.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(ChatbotApp());
}

class ChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: Color(0xFF3E78B2),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatBotScreen(),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
  ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  TextEditingController userInputController = TextEditingController();
  bool? hasIrepsAccount;
  bool isWaitingForSubmission = false;
  bool isTyping = false;
  String? firmName,
      unit,
      UserName,
      designation,
      queryDescription,
      queryType,
      subject,
      organizationType,
      zone;
  String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String currentQuestion = "initial";
  String _queryId = "";
  String queryStatusQueryId = "";
  String queryStatusEmail = "";
  String userEmail = "";
  String mobileNo = "";
  String userDepartment = "";
  String dscUpdateEmail = "";
  late AnimationController _typingDotsController;
  final Map<String, List<String>> zoneOptions = {
    "Indian Railway": [
      "Banaras Locomotive Works",
      "COFMOW",
      "CORE",
      "Central Railway",
      "Chittaranjan Locomotive Works",
      "East Central Railway",
      "East Coast Railway",
      "Eastern Railway",
      "IREPS TESTING2",
      " IREPS-TESTING",
      "Other"
    ],
    "KRCL": ["konkan Railway Corporation Ltd", "Other"],
    "DMRC": ["DMRC", "Other"],
    "MRVC": ["MRVC", "Other"],
    "CRIS": ["CRIS", " CRIS-IMMS TESTING", " Other"],
    "RIETS Limited": ["RITES Corporate Office", "Other"],
    "RAILTEL": [
      "Railtel Corporate Office",
      "Railtel Eastern Region",
      " Railtel Nothem Region",
      "Railtel Southern Region",
      "Railtel Western Region"
          "Other"
    ],
    "DFCCIL": ["DFC Corporate office", " EDFC", "WDFC", "Other"],
    "KERELA RAIL DEVELOPMENT CORPORATION LTD": ["KRDCL HQ", "Other"],
    "INDIAN RAILWAY CATERING AND TOURISM CORPORATION LTD": [
      "IRCTC CORPORATE OFFICE"
    ],
    "CONTAINER CORPORATION OF INDIA LTD": ["CONCOR Corporate Office", "Other"],
    "BRAITHWAITE AND CO.LIMITED": ["BCL Corporate Office", "Other"],
    "RAIL VIKAS NIGAM LIMITED": ["RVNL", "Other"],
    "INDIAN RAILWAY FINANCE CORPORATION": ["IRFC Corporate Office ", "Other"],
    "IRCON INTERNATIONAL LIMITED": ["IRCON Corporate Office ", "Other"],
    "KOLKATA METRO RAIL CORPORATION LTD": ["KMRCL Corporate Office ", "Other"],
    "Other": []
  };
  final Map<String, List<String>> subjectOptions = {
    "User Depot Module": [
      "User Creation",
      "Miscellaneous",
      "Suggestion",
      "Demand",
      "Receipt",
      "Ledger",
      "Stock Verification"
    ],
    "Goods & Service Tender": [
      "Department Creation",
      "Miscellaneous",
      "Suggestion",
      "System Settings",
      "Tender Tabulations"
    ],
    "U-VAM": ["Miscellaneous"],
    "Works Tender": [
      "Department Creation",
      "Miscellaneous",
      "Suggestion",
      "System Settings",
      "Tender Tabulations"
    ],
    "Inspection": [
      "Dm-Dispatch Memo",
      "IC-Inspection Certificate",
      "Miscellaneous"
    ],
    "Earning/Leasing Tender": [
      "Department Creation",
      "Miscellaneous",
      "Suggestion",
      "System Settings",
      "Tender Tabulations"
    ],
    "E-Auction Leasing": ["Miscellaneous"],
    "E-Auction(sale)": ["Miscellaneous"],
    "iMMS": [
      "Miscellaneous",
      "Suggestions",
      "Queries/Reports",
      "AAC updation",
      "Tender Preparation"
    ],
    "Mobile App": [
      "Miscellaneous",
      "Suggestions",
      "Before Login Issue",
      " After Login Issue"
    ]
  };
  @override
  void initState() {
    super.initState();
    _typingDotsController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    )..repeat();
    _setupScrollListener();
    resetChat();
  }
  void dispose() {
    _scrollController.dispose();
    userInputController.dispose();
    _typingDotsController.dispose();
    super.dispose();
  }
  void goToPreviousMessage() {
    setState(() {
      if (messages.length >= 2) {
        messages.removeLast();
        messages.removeLast();
        currentQuestion = getPreviousQuestion();
      }
    });
  }

  String getPreviousQuestion() {
    if (messages.isNotEmpty) {
      var lastBotMessage = messages.last['bot'];
      if (lastBotMessage != null) {
        if (lastBotMessage.contains("What do you want?")) {
          return "initialMenu";
        } else if (lastBotMessage
            .contains("Do you have a user account on IREPS?")) {
          return "hasAccount";
        } else if (lastBotMessage.contains("Your email?")) {
          return "email";
        } else if (lastBotMessage.contains("User Type(Your Department)?")) {
          return "department";
        } else if (lastBotMessage.contains("Your Firm Name?")) {
          return "firmName";
        } else if (lastBotMessage.contains("UserName?")) {
          return "UserName";
        } else if (lastBotMessage.contains("Your Mobile No.?")) {
          return "mobileNo";
        } else if (lastBotMessage.contains("In which Organization you are?")) {
          return "organization";
        } else if (lastBotMessage.contains("In which Zone you are?")) {
          return "zone";
        } else if (lastBotMessage.contains("In which Unit you are?")) {
          return "unit";
        } else if (lastBotMessage.contains("Query related to?")) {
          return "query";
        } else if (lastBotMessage.contains("Your subject?")) {
          return "subject";
        } else if (lastBotMessage.contains("Give Query Description")) {
          return "queryDescription";
        }
      }
    }
    return "initialMenu";
  }

  String getQuestionText(String questionKey) {
    switch (questionKey) {
      case "initialMenu":
        return "What do you want?";
      case "raiseQueryStart":
        return "Hey! I'm your IREPS Assistant. How can I help you today?";
      case "hasAccount":
        return "Do you have a user account on IREPS?";
      case "email":
        return "Your email?";
      case "department":
        return "User Type(Your Department)?";
      case "firmName":
        return "Your Firm Name?";
      case "UserName":
        return "UserName?";
      case "mobileNo":
        return "Your Mobile No.?";
      case "organization":
        return "In which Organization you are?";
      case "zone":
        return "In which Zone you are?";
      case "unit":
        return "In which Unit you are ?";
      case "designation":
        return "Designation/Post?";
      case "query":
        return "Query related to?";
      case " Your subject":
        return "Your subject?";
      case "queryDescription":
        return "Give Query Description";
      default:
        return "What do you want?";
    }
  }

  List<String> getOptions() {
    switch (currentQuestion) {
      case "initialMenu":
        return ["Raise Web Query", "Web Query Status", "Registration Request Status"];
      case "requestStatusMenu":
        return ["Registration Request Status", "DSC Update Request"];
      case "queryStatusOptions":
        return ["Ask supplementary question", "Back to the main menu", "Other query details"];
      case "hasAccount":
        return ["Yes", "No"];
      case "department":
        return [
          "Vendor/Contractor/Auction Bidder",
          "Railway/Departmental User"
        ];
      case "organization":
        return [
          "Indian Railway",
          "KRCL",
          "DMRC",
          "MRVC",
          "CRIS",
          "RIETS Limited",
          "RAILTEL",
          "DFCCIL",
          "KERELA RAIL DEVELOPMENT CORPORATION LTD",
          "INDIAN RAILWAY CATERING AND TOURISM CORPORATION LTD",
          "CONTAINER CORPORATION OF INDIA LTD",
          "BRAITHWAITE AND CO.LIMITED",
          "RAIL VIKAS NIGAM LIMITED",
          "INDIAN RAILWAY FINANCE CORPORATION",
          "IRCON INTERNATIONAL LIMITED",
          "KOLKATA METRO RAIL CORPORATION LTD",
          "Other"
        ];
      case "query":
        return [
          "U-VAM",
          "Works Tender",
          "iMMS",
          "Inspection",
          "Mobile App",
          "User Depot Module",
          "Goods & Service Tender",
          "Earning/Leasing Tender",
          "E-Auction Leasing",
          "E-Auction(Sale)",
        ];
      case "unit":
        return ["Unit 1", "Unit 2"];
      case "submitConfirmation":
        return ["Yes", "No"];
      case "attachDocuments":
        return ["Yes", "No"];
      case "queryStatusFound":
        return ["Yes", "No"];
      case "dscUpdateConfirm":
        return ["Update DSC"];
      case "subject":
        if (queryType != null) {
          return subjectOptions[queryType!] ?? [];
        }
        return [];
      case "zone":
        if (organizationType != null) {
          return zoneOptions[organizationType!] ?? [];
        }
        return [];
      case "registrationStatusWithDSC":
        return ["DSC Update"];
      case "registrationEmailNotFound":
        return ["Enter registered email", "Back to the main menu"];
      default:
        return [];
    }
  }
  void resetChat() {
    setState(() {
      messages.clear();
      currentQuestion = "initialMenu";
      hasIrepsAccount = null;
      firmName = null;
      unit = null;
      UserName = null;
      designation = null;
      queryDescription = null;
      queryType = null;
      subject = null;
      organizationType = null;
      zone = null;
      userEmail = "";
      mobileNo = "";
      userDepartment = "";
      _queryId = "";
      queryStatusQueryId = "";
      queryStatusEmail = "";
      dscUpdateEmail = "";

      _showTypingIndicator();

      Future.delayed(Duration(milliseconds: 300), () {
        setState(() {
          isTyping = false;
          messages.add({
            'bot': "What do you want?",
            'timestamp': DateTime.now().toString(),
          });
          _scrollToBottom();
        });
      });
    });
  }
  void _showTypingIndicator() {
    setState(() {
      isTyping = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _generateQueryId() async {
    setState(() {
      _queryId = "QID${Random().nextInt(100000)}";
    });

    final messageContent = {
      'bot': "Query Submitted Successfully.\n\n"
          "Query ID: $_queryId\n"
          "Email: $userEmail\n"
          "Mobile No: $mobileNo\n"
          "${designation != null && designation!.isNotEmpty ? 'Designation: $designation\n' : ''}"
          "Date: $currentDate\n"
          "Query Description: $queryDescription",
      'timestamp': DateTime.now().toString(),
    };

    setState(() {
      messages.add(messageContent);
      messages.add({
        'bot': "Would you like to attach documents to this query?",
        'timestamp': DateTime.now().toString(),
      });
      currentQuestion = "attachDocuments";
      _scrollToBottom();
    });
    Map<String, dynamic> userData = {
      'has_ireps_account': hasIrepsAccount.toString(),
      'email': userEmail,
      'mobile': mobileNo,
      'department': userDepartment,
      'firm_name': firmName,
      'user_name': UserName,
      'organization': organizationType,
      'zone': zone,
      'unit': unit,
      'designation': designation,
      'query_id': _queryId,
      'query_type': queryType,
      'subject': subject,
      'query_description': queryDescription
    };

    try {
      await DatabaseHelper.instance.insertResponse(userData);
    } catch (e) {
      print("Error saving query: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  void _scrollToTop({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }
  bool _isAtBottom() {
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
  }
  bool _isAtTop() {
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.pixels <= 50;
  }
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
        });
      }
    });
  }
  void handleUserResponse(String response) {
    setState(() {
      messages.add({
        'user': response,
        'timestamp': DateTime.now().toString(),
      });
      userInputController.clear();
      _showTypingIndicator();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    Future.delayed(Duration(milliseconds: 300), () async {
      setState(() {
        isTyping = false;
      });
      await processNextStep(response);

      if (currentQuestion == "query") {
        queryType = response;
      } else if (currentQuestion == "subject") {
        subject = response;
      }
      if (currentQuestion == "organization") {
        organizationType = response;
      } else if (currentQuestion == "zone") {
        zone = response;
      }
    });
  }

  void _delayedBotResponse(String message, int delay, {String? nextQuestion}) {
    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: delay < 500 ? delay : 500), () {
      setState(() {
        isTyping = false;
        messages.add({
          'bot': message,
          'timestamp': DateTime.now().toString(),
        });
        if (nextQuestion != null) {
          currentQuestion = nextQuestion;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }
  Future<bool> _validateDscEmail(String email) async {
    try {
      Map<String, dynamic>? userData = await DatabaseHelper.instance.getUserByEmail(email);
      return userData != null;
    } catch (e) {
      print("Error validating DSC email: $e");
      return false;
    }
  }
  Future<void> _checkQueryStatus(String queryId, String email) async {
    try {
      // Check in user_responses table first
      Map<String, dynamic>? queryData = await DatabaseHelper.instance
          .getUserResponseByQueryIdAndEmail(queryId, email);

      if (queryData != null) {
        await _displayQueryDetails(queryData, queryId);
      } else {
        // If not found in user_responses, check in queries table
        Map<String, dynamic> basicQuery = await DatabaseHelper.instance.getQueryById(queryId);
        if (basicQuery.isNotEmpty) {
          await _displayBasicQueryDetails(basicQuery, queryId);
        } else {
          _delayedBotResponse(
              "❌ No query found with Query ID: $queryId and Email: $email\n\n"
                  "Please check your Query ID and Email address and try again.", 1000);
          currentQuestion = "initialMenu";
          Future.delayed(Duration(milliseconds: 2000), () {
            resetChat();
          });
        }
      }
    } catch (e) {
      print('Error checking query status: $e');
      _delayedBotResponse(
          "❌ An error occurred while checking your query status. Please try again.", 1000);
      currentQuestion = "initialMenu";
      Future.delayed(Duration(milliseconds: 2000), () {
        resetChat();
      });
    }
  }
  Future<void> _displayQueryDetails(Map<String, dynamic> queryData, String queryId) async {
    // Get documents for this query
    List<Map<String, dynamic>> documents = await DatabaseHelper.instance
        .getDocumentsByQueryId(queryId);

    String documentsText = "";
    if (documents.isNotEmpty) {
      documentsText = "\n\n📎 **Attached Documents:**\n";
      for (int i = 0; i < documents.length; i++) {
        var doc = documents[i];
        String docName = doc['document_name'] ?? doc['name'] ?? "Document ${i + 1}";
        String docDesc = doc['document_description'] ?? doc['description'] ?? "No description";
        String filePath = doc['file_path'] ?? doc['fileName'] ?? "";
        if (filePath.isNotEmpty) {
          documentsText += "• $docName\n  Description: $docDesc\n ($filePath)\n";
        } else {
          documentsText += "• $docName\n  Description: $docDesc\n";
        }
      }
    } else {
      documentsText = "\n\n📎 **Attached Documents:** None";
    }

    String queryCreatedDate = DatabaseHelper.formatDateTimeForDisplay(queryData['created_at']);
    String replyDate = DatabaseHelper.formatDateTimeForDisplay(queryData['reply_date']);
    String replyMessage = queryData['reply_message'] ?? "Reply is being processed. Please check back later.";
    String queryDescription = queryData['query_description'] ?? "No description available";

    String statusMessage = "✅ **Query Found!**\n\n"
        "📅 **Query Created On:** $queryCreatedDate\n\n"
        "📝 **Query Description:**\n$queryDescription\n\n"
        "📬 **Reply Created On:** $replyDate\n\n"
        "💬 **Reply Message:**\n$replyMessage"
        "$documentsText\n\n"
        "What would you like to do next?";

    setState(() {
      isTyping = false;
      messages.add({
        'bot': statusMessage,
        'timestamp': DateTime.now().toString(),
      });
      currentQuestion = "queryStatusOptions"; // Changed from "queryStatusFound"
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _displayBasicQueryDetails(Map<String, dynamic> queryData, String queryId) async {
    List<Map<String, dynamic>> documents = await DatabaseHelper.instance
        .getDocumentsByQueryId(queryId);

    String documentsText = "";
    if (documents.isNotEmpty) {
      documentsText = "\n\n📎 **Attached Documents:**\n";
      for (int i = 0; i < documents.length; i++) {
        var doc = documents[i];
        String docName = doc['document_name'] ?? doc['name'] ?? "Document ${i + 1}";
        String docDesc = doc['document_description'] ?? doc['description'] ?? "No description";
        String filePath = doc['file_path'] ?? doc['fileName'] ?? "";
        if (filePath.isNotEmpty) {
          documentsText += "• $docName\n  Description: $docDesc\n($filePath)\n";
        } else {
          documentsText += "• $docName\n  Description: $docDesc\n";
        }
      }
    } else {
      documentsText = "\n\n📎 **Attached Documents:** None";
    }

    String queryCreatedDate = DatabaseHelper.formatDateTimeForDisplay(queryData['date_created']);
    String queryDescription = queryData['query_description'] ?? "No description available";

    String statusMessage = "✅ **Query Found!**\n\n"
        "📅 **Query Created On:** $queryCreatedDate\n\n"
        "📝 **Query Description:**\n$queryDescription\n\n"
        "📬 **Reply Created On:** Not available\n\n"
        "💬 **Reply Message:**\nReply is being processed. Please check back later."
        "$documentsText\n\n"
        "What would you like to do next?";

    setState(() {
      isTyping = false;
      messages.add({
        'bot': statusMessage,
        'timestamp': DateTime.now().toString(),
      });
      currentQuestion = "queryStatusOptions"; // Changed from "queryStatusFound"
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _saveSupplementaryQuestion(String queryId, String email, String question) async {
    try {
      await DatabaseHelper.instance.createSupplementaryQuestionsTable();

      Map<String, dynamic> supplementaryData = {
        'original_query_id': queryId,
        'email': email,
        'supplementary_question': question,
      };

      await DatabaseHelper.instance.insertSupplementaryQuestion(supplementaryData);
      print('Supplementary question saved successfully');
    } catch (e) {
      print('Error saving supplementary question: $e');
    }
  }

  Future<void> processNextStep(String response) async {
    switch (currentQuestion) {
      case "initialMenu":
        if (response == "Raise Web Query") {
          _delayedBotResponse(
              "Hey! I'm your IREPS Assistant. How can I help you today?", 700);
          _delayedBotResponse("Do you have a user account on IREPS?", 1400,
              nextQuestion: "hasAccount");
        } else if (response == "Web Query Status") {
          _delayedBotResponse(
              "!Welcome to Query Status Check!\n"
                  "Track your query updates with ease.\n"
                  "To view a response, please enter your Query ID and E-mail ID."
              "Feel free to submit supplementary questions if needed.", 700);
          _delayedBotResponse("Please provide your Query ID:", 1400,
              nextQuestion: "queryStatusQueryId");
        } else if (response == "Registration Request Status") {
          _delayedBotResponse(
              "Welcome to Registration Request Status! 📋\n\n"
                  "Please provide your registered Email ID to check the registration status:", 700,
              nextQuestion: "registrationStatusEmail");
        }
        break;
      case "requestStatusMenu":
        if (response == "Registration Request Status") {
          _delayedBotResponse(
              "Welcome to Registration Request Status! 📋\n\n"
                  "Please provide your registered Email ID to check the registration status:", 700,
              nextQuestion: "registrationStatusEmail");
        } else if (response == "DSC Update Request") {
          _delayedBotResponse(
              "**- Request for Change of Digital Signing Certificate**\n"
                  "(Client Name in new DSC should be exactly same as mentioned in the IREPS user account)", 700);
          _delayedBotResponse("Please provide your registered Email ID for DSC update:", 1400,
              nextQuestion: "dscUpdateEmail");
        }
        break;

      case "dscUpdateEmail":
        if (!_isValidEmail(response)) {
          _delayedBotResponse(
              "Invalid email format. Please enter a valid email address.", 700,
              nextQuestion: "dscUpdateEmail"); // Keep the same question state
        } else {
          bool isRegistered = await _validateDscEmail(response.trim());
          if (isRegistered) {
            dscUpdateEmail = response.trim();
            _delayedBotResponse(
                "✅ Email verified successfully!\n\n"
                    "Your registered email: $dscUpdateEmail\n\n"
                    "Click the button below to proceed with DSC update:", 700,
                nextQuestion: "dscUpdateConfirm");
          } else {
            _delayedBotResponse(
                "❌ This email is not registered in IREPS system.\n"
                    "Please enter a registered email address.", 700,
                nextQuestion: "dscUpdateEmailOptions"); // Changed to show options
          }
        }
        break;
      case "dscUpdateEmailOptions":
        if (response == "Back to the main menu") {
          _delayedBotResponse(
              "Welcome back! How can I help you?", 700);
          Future.delayed(Duration(milliseconds: 1000), () {
            resetChat();
          });
        } else if (response == "Another registered email") {
          _delayedBotResponse(
              "Please provide your registered Email ID for DSC update:", 700,
              nextQuestion: "dscUpdateEmail");
        }
        break;
      case "dscUpdateConfirm":
        if (response == "Update DSC") {
          // _delayedBotResponse(
          //     "🔄 Processing DSC update request...", 500);
          Future.delayed(Duration(milliseconds: 1500), () {
            _delayedBotResponse(
                "✅ DSC Update Request Submitted Successfully!\n\n"
                    "📧 Email: $dscUpdateEmail\n"
                    "📅 Request Date: $currentDate\n"
                    "🆔 Request ID: DSC${Random().nextInt(100000)}\n\n"
                    "Your request for DSC update has been registered with us. "
                    "Please wait for atleast 3 working days to get your DSC updated.", 700);

            Future.delayed(Duration(milliseconds: 2000), () {
              _delayedBotResponse(
                  "Is there anything else I can help you with?", 700,
                  nextQuestion: "initialMenu");
            });
          });
        }
        break;
      case "registrationStatusEmail":
        if (!_isValidEmail(response)) {
          _delayedBotResponse(
              "Invalid email format. Please enter a valid email address.", 700);
        } else {
          String registrationEmail = response.trim();
          // Check if email exists in system
          bool isRegistered = await _validateDscEmail(registrationEmail);
          if (isRegistered) {
            _delayedBotResponse(
                "✅ Email verified successfully!\n\n"
                    "📧 Registered Email: $registrationEmail\n"
                    "📅 Check Date: $currentDate\n\n"
                    "Your registration request status: **Approved**\n"
                    "Your account is active and ready to use.", 700,
                nextQuestion: "registrationStatusWithDSC");
          } else {
            _delayedBotResponse(
                "❌ This email is not registered in IREPS system.\n"
                    "Please choose an option below:", 700,
                nextQuestion: "registrationEmailNotFound"); // Changed this line
          }
        }
        break;
      case "registrationEmailNotFound":
        if (response == "Enter registered email") {
          _delayedBotResponse(
              "Please provide your registered Email ID to check the registration status:", 700,
              nextQuestion: "registrationStatusEmail");
        } else if (response == "Back to the main menu") {
          _delayedBotResponse(
              "Welcome back! How can I help you?", 700);
          Future.delayed(Duration(milliseconds: 1000), () {
            resetChat();
          });
        }
        break;
      case "registrationStatusWithDSC":
        if (response == "DSC Update") {
          dscUpdateEmail = queryStatusEmail.isNotEmpty ? queryStatusEmail : userEmail;
          Future.delayed(Duration(milliseconds: 1500), () {
            _delayedBotResponse(
                "✅ DSC Update Request Submitted Successfully!\n\n"
                    "📧 Email: $dscUpdateEmail\n"
                    "📅 Request Date: $currentDate\n"
                    "🆔 Request ID: DSC${Random().nextInt(100000)}\n\n"
                    "Your request for DSC update has been registered with us. "
                    "Please wait for atleast 3 working days to get your DSC updated.", 700);

            Future.delayed(Duration(milliseconds: 2000), () {
              _delayedBotResponse(
                  "Is there anything else I can help you with?", 700,
                  nextQuestion: "initialMenu");
            });
          });
        }
        break;
      case "registrationStatusToUpdate":
        if (response.toLowerCase() == "yes") {
          _delayedBotResponse(
              "**- Request for Change of Digital Signing Certificate**\n"
                  "(Client Name in new DSC should be exactly same as mentioned in the IREPS user account)", 700);
          _delayedBotResponse("Please provide your registered Email ID for DSC update:", 1400,
              nextQuestion: "dscUpdateEmail");
        } else {
          _delayedBotResponse(
              "Thank you for checking your registration status. Is there anything else I can help you with?", 700);
          Future.delayed(Duration(milliseconds: 1500), () {
            resetChat();
          });
        }
        break;

      case "queryStatusQueryId":
        if (response.trim().isEmpty) {
          _delayedBotResponse(
              "Query ID cannot be empty. Please enter a valid Query ID.", 700);
        } else {
          queryStatusQueryId = response.trim();
          _delayedBotResponse("Please provide your Email ID:", 700,
              nextQuestion: "queryStatusEmail");
        }
        break;

      case "queryStatusEmail":
        if (!_isValidEmail(response)) {
          _delayedBotResponse(
              "Invalid email format. Please enter a valid email address.", 700);
        } else {
          queryStatusEmail = response.trim();
          _checkQueryStatus(queryStatusQueryId, queryStatusEmail);
        }
        break;
      case "queryStatusOptions":
        if (response == "Ask supplementary question") {
          _delayedBotResponse(
              "Please enter your supplementary question:", 700,
              nextQuestion: "supplementaryQuestion");
        } else if (response == "Back to the main menu") {
          _delayedBotResponse(
              "Welcome back! How can I help you?", 700);
          Future.delayed(Duration(milliseconds: 1000), () {
            resetChat();
          });
        } else if (response == "Other query details") {
          _delayedBotResponse(
              "Please provide your Query ID:", 700,
              nextQuestion: "queryStatusQueryId");
        }
        break;
      case "supplementaryQuestion":
        if (response.trim().length < 10) {
          _delayedBotResponse(
              "Please enter at least 10 characters for your supplementary question.", 700);
        } else {
          await _saveSupplementaryQuestion(queryStatusQueryId, queryStatusEmail, response.trim());
          _delayedBotResponse(
              "Your supplementary question has been recorded successfully! ✅\n\n"
                  "We will get back to you soon.", 700);
          currentQuestion = "initialMenu";
          resetChat();
        }
        break;
      case "hasAccount":
        hasIrepsAccount = response.toLowerCase() == "yes";
        _delayedBotResponse("Your email?", 700);
        currentQuestion = "email";
        break;
      case "email":
        if (_isValidEmail(response)) {
          userEmail = response;
          if (hasIrepsAccount!) {
            try {
              Map<String, dynamic>? userData =
              await DatabaseHelper.instance.getUserByEmail(userEmail);
              if (userData != null) {
                int userId = userData['id'];
                mobileNo = userData['mobile'] ?? "";
                userDepartment = userData['department'] ?? "";
                if (userDepartment == "Vendor/Contractor/Auction Bidder") {
                  List<Map<String, dynamic>> vendorData =
                  await DatabaseHelper.instance.query('vendor_details',
                      where: 'user_id = ?', whereArgs: [userId]);
                  if (vendorData.isNotEmpty) {
                    firmName = vendorData.first['firm_name'] ?? "";
                    UserName = vendorData.first['user_name'] ?? "";
                  }
                  _delayedBotResponse(
                      "Your Registered Details are:\n"
                          " Email: $userEmail\n"
                          " Mobile No.: $mobileNo\n"
                          " Firm Name: $firmName\n"
                          " Username: $UserName\n"
                          " Department: $userDepartment",
                      700);
                } else if (userDepartment == "Railway/Departmental User") {
                  List<Map<String, dynamic>> railwayData = await DatabaseHelper
                      .instance
                      .query('railway_user_details',
                      where: 'user_id = ?', whereArgs: [userId]);
                  if (railwayData.isNotEmpty) {
                    organizationType = railwayData.first['organization'] ?? "";
                    zone = railwayData.first['zone'] ?? "";
                    unit = railwayData.first['unit'] ?? "";
                    designation = railwayData.first['designation'] ??
                        "";
                  }
                  _delayedBotResponse(
                      "Your Registered Details are:\n"
                          " Email: $userEmail\n"
                          " Mobile No.: $mobileNo\n"
                          " Organization: $organizationType\n"
                          " Zone: $zone\n"
                          " Unit: $unit\n"
                          " Designation: $designation\n"
                          " Department: $userDepartment",
                      700);
                }
                _delayedBotResponse("Query related to?", 2000,
                    nextQuestion: "query");
              } else {
                _delayedBotResponse(
                    "No registered account found with this email. Please provide your details.",
                    700);
                _delayedBotResponse("User Type(Your Department)?", 1500);
                currentQuestion = "department";
              }
            } catch (e) {
              print("Error fetching user data: $e");
              _delayedBotResponse("You don't have an IREPS account.", 700);
              _delayedBotResponse("User Type(Your Department)?", 1500);
              currentQuestion = "department";
            }
          } else {
            _delayedBotResponse("User Type(Your Department)?", 700);
            currentQuestion = "department";
          }
        } else {
          _delayedBotResponse(
              "Invalid email format. Please enter a valid email.", 700);
        }
        break;
      case "department":
        userDepartment = response;
        _delayedBotResponse(
            userDepartment == "Vendor/Contractor/Auction Bidder"
                ? "Your Firm Name?"
                : "In which Organization you are?",
            700);
        currentQuestion = userDepartment == "Vendor/Contractor/Auction Bidder"
            ? "firmName"
            : "organization";
        break;
      case "firmName":
        firmName = response;
        _delayedBotResponse("UserName?", 700);
        currentQuestion = "UserName";
        break;
      case "UserName":
        if (response.trim().isEmpty) {
          _delayedBotResponse(
              "Username cannot be empty. Please enter a valid username.", 700);
        } else if (_isValidUserName(response)) {
          UserName = response;
          _delayedBotResponse("Your Mobile No.?", 700);
          currentQuestion = "mobileNo";
        } else {
          _delayedBotResponse(
              "Invalid username. Username must start with a letter and be 3-20 characters long. It can include letters, numbers, spaces, underscores, and special characters.",
              700);
        }
        break;
      case "mobileNo":
        if (_isValidMobile(response)) {
          mobileNo = response;
          _delayedBotResponse("Query related to?", 700);
          currentQuestion = "query";
        } else {
          _delayedBotResponse(
              "Invalid mobile number. Please enter a 10-digit valid number.",
              700);
        }
        break;
      case "organization":
        organizationType = response;
        if (response == "Other") {
          _delayedBotResponse("Your Mobile No.?", 700);
          currentQuestion = "mobileNo";
        } else {
          _delayedBotResponse("In which Zone you are?", 700,
              nextQuestion: "zone");
        }
        break;
      case "customOrganization":
        organizationType = response;
        _delayedBotResponse("In which Zone you are?", 700,
            nextQuestion: "zone");
        break;
      case "zone":
        zone = response;
        if (response == "Other") {
          _delayedBotResponse("Your Mobile No.?", 700);
          currentQuestion = "mobileNo";
        } else {
          _delayedBotResponse("In which unit you are?", 700,
              nextQuestion: "unit");
        }
        break;
      case "customZone":
        zone = response;
        _delayedBotResponse("In which unit you are?", 700,
            nextQuestion: "unit");
        break;
      case "unit":
        unit = response;
        if (response == "Other") {
          if (hasIrepsAccount == false) {
            _delayedBotResponse("Designation/Post?", 700);
            currentQuestion = "designation";
          } else {
            _delayedBotResponse("Your Mobile No.?", 700);
            currentQuestion = "mobileNo";
          }
        } else {
          if (hasIrepsAccount == false) {
            _delayedBotResponse("Designation/Post?", 700);
            currentQuestion = "designation";
          } else {
            _delayedBotResponse("Your Mobile No.?", 700);
            currentQuestion = "mobileNo";
          }
        }
        break;
      case "customUnit":
        unit = response;
        if (hasIrepsAccount == false) {
          _delayedBotResponse("Designation/Post?", 700);
          currentQuestion = "designation";
        } else {
          _delayedBotResponse("Your Mobile No.?", 700);
          currentQuestion = "mobileNo";
        }
        break;
      case "designation":
        designation = response;
        _delayedBotResponse("Your Mobile No.?", 700);
        currentQuestion = "mobileNo";
        break;
      case "query":
        queryType = response;
        _delayedBotResponse("Your subject?", 700, nextQuestion: "subject");
        break;
      case "subject":
        subject = response;
        _delayedBotResponse("Give query description", 700,
            nextQuestion: "queryDescription");
        break;
      case "queryDescription":
        if (response.trim().length < 20) {
          _delayedBotResponse(
              "Please enter at least 20 characters in the Description field.",
              700,
              nextQuestion:
              "queryDescription"
          );
        } else {
          queryDescription = response.trim();
          _delayedBotResponse("Do you want to submit this query?", 700,
              nextQuestion: "submitConfirmation");
        }
        break;
      case "submitConfirmation":
        if (response.toLowerCase() == "yes") {
          _generateQueryId();
        } else {
          _delayedBotResponse(
              "Query submission cancelled. How can I help you further?", 700);
          resetChat();
        }
        break;
      case "attachDocuments":
        if (response.toLowerCase() == "yes") {
          Navigator.push(
            context,
            SlidePageRoute(
              page: AttachDocumentsPage(queryId: _queryId),
              direction: AxisDirection.up,
            ),
          ).then((_) {
            _delayedBotResponse(
              "Thank you! Your query has been recorded.",
              700,
            );
            currentQuestion = "initialMenu";
            resetChat();
          });
        } else {
          _delayedBotResponse(
            "Thank you! Your query has been recorded.",
            700,
          );
          currentQuestion = "initialMenu";
          resetChat();
        }
        break;
      case "viewHistory":
        if (response.toLowerCase() == "yes") {
          Navigator.push(
            context,
            SlidePageRoute(page: HistoryPage()),
          ).then((_) {
            resetChat();
          });
        } else {
          resetChat();
        }
        break;
      case "queryStatusCheck":
        _delayedBotResponse("Checking status for Query ID: $response", 700);
        currentQuestion = "initialMenu";
        break;
      case "requestStatusCheck":
        _delayedBotResponse("Checking status for Request ID: $response", 700);
        currentQuestion = "initialMenu";
        break;
    }
  }

  bool _isValidEmail(String? email) {
    if (email == null) return false;
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidMobile(String mobile) {
    RegExp regex = RegExp(
        r'^[6-9]\d{9}$');
    return regex.hasMatch(mobile) && mobile.length == 10;
  }

  bool _isValidUserName(String UserName) {
    final RegExp regex =
    RegExp(r'^[a-zA-Z][a-zA-Z0-9 _@#\$%\^\&\*\(\)\-]{2,19}$');
    return regex.hasMatch(UserName);
  }
  Widget buildDocumentList(List<Map<String, dynamic>> documents) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final filePath = doc['file_path'] ?? doc['fileName'] ?? "";
        final docName = doc['document_name'] ?? doc['name'] ?? "Document ${index + 1}";
        final docDesc = doc['document_description'] ?? doc['description'] ?? "No description";
        return ListTile(
          leading: Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text(docName),
          subtitle: Text(docDesc),
          trailing: Icon(Icons.open_in_new),
          onTap: () async {
            if (filePath.isNotEmpty) {
              await OpenFile.open(filePath);
            }
          },
        );
      },
    );
  }

  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(Icons.assistant, color: Color(0xFF075E54), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              "IREPS Assistant",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          if (messages.length > 1)
            IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: HistoryPage(),
                    direction: AxisDirection.up,
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: goToPreviousMessage,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: resetChat,
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    ...List.generate(messages.length, (index) {
                      bool isBot = messages[index].containsKey('bot');
                      bool isFirstInSequence = index == 0 ||
                          (messages[index].containsKey('bot') !=
                              messages[index - 1].containsKey('bot'));
                      return Column(
                        crossAxisAlignment: isBot
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          if (isFirstInSequence)
                            Padding(
                              padding: EdgeInsets.only(
                                left: isBot ? 12 : 0,
                                right: isBot ? 0 : 12,
                                top: 8,
                                bottom: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isBot) ...[
                                    CircleAvatar(
                                      backgroundColor: Color(0xFF075E54),
                                      radius: 12,
                                      child: Icon(
                                        Icons.assistant,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Assistant",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      "You",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    CircleAvatar(
                                      backgroundColor: Color(0xFF075E54),
                                      radius: 12,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          Align(
                            alignment: isBot
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width *
                                    0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isBot
                                    ? Colors.white
                                    : Color(0xFFDCF8C6),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isBot ? 0 : 12),
                                  topRight: Radius.circular(isBot ? 12 : 0),
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: 45),
                                    child: Text(
                                      isBot
                                          ? messages[index]['bot']
                                          : messages[index]['user'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Text(
                                      _formatTimestamp(
                                          messages[index]['timestamp']),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isBot &&
                              index == messages.length - 1 &&
                              getOptions().isNotEmpty)
                            (() {
                              List<String> options = getOptions();
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: options.map((option) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => handleUserResponse(option),
                                            splashColor: Color(0xFF075E54).withOpacity(0.1),
                                            highlightColor: Color(0xFF075E54).withOpacity(0.05),
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.08),
                                                    spreadRadius: 0,
                                                    blurRadius: 3,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 4,
                                                ),
                                                child: Text(
                                                  option,
                                                  style: TextStyle(
                                                    color: Color(0xFF2E7D32),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            })(),
                        ],
                      );
                    }),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            if (messages.isNotEmpty &&
                messages.last.containsKey('bot') &&
                getOptions().isEmpty &&
                currentQuestion != "initialMenu" &&
                currentQuestion != "queryStatusCheck" &&
                currentQuestion != "requestStatusCheck")
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 5,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: userInputController,
                                maxLength: currentQuestion == "mobileNo" ? 10 : null,
                                keyboardType: currentQuestion == "mobileNo"
                                    ? TextInputType.number
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: currentQuestion == "mobileNo"
                                      ? "Enter your 10-digit mobile number..."
                                      : currentQuestion == "queryStatusCheck"
                                      ? "Enter Query ID..."
                                      : currentQuestion == "requestStatusCheck"
                                      ? "Enter Request ID..."
                                      : "Type your message...",
                                  hintStyle: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  counterText: currentQuestion == "mobileNo" ? "" : null,
                                ),
                                style: TextStyle(color: Colors.black87),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    handleUserResponse(value);
                                  }
                                },
                              ),
                            ),
                            if (userInputController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey[600], size: 20),
                                onPressed: () {
                                  setState(() {
                                    userInputController.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF075E54),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white, size: 22),
                        onPressed: () {
                          if (userInputController.text.isNotEmpty) {
                            handleUserResponse(userInputController.text);
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(String timestamp) {
  final DateTime dateTime = DateTime.parse(timestamp);
  final String formattedTime = DateFormat('h:mm a').format(dateTime);
  return formattedTime;
}

String getFormattedDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final aDate = DateTime(date.year, date.month, date.day);
  final difference = aDate.difference(today).inDays;

  if (difference == 0) return 'Today';
  if (difference == -1) return 'Yesterday';
  if (difference == 1) return 'Tomorrow';
  return DateFormat('EEEE, MMMM d').format(date);
}