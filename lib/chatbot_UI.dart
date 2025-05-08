import 'dart:core';
import 'dart:math';
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
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  TextEditingController userInputController = TextEditingController();
  ScrollController _scrollController = ScrollController();
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
  String userEmail = "";
  String mobileNo = "";
  String userDepartment = "";
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

    // Add listener to scroll controller
    _scrollController.addListener(() {
      // If we're near the bottom, auto-scroll to bottom on any change
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 150) {
        _scrollToBottom();
      }
    });

    resetChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures scroll to bottom when the view is first built
      _scrollToBottom();
    });
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
        messages.removeLast(); // Remove bot's question
        messages.removeLast(); // Remove user's answer
        currentQuestion = getPreviousQuestion();
        // no need to add again if you show from currentQuestion
      }
    });
  }

  String getPreviousQuestion() {
    if (messages.isNotEmpty) {
      var lastBotMessage = messages.last['bot'];
      if (lastBotMessage != null) {
        if (lastBotMessage.contains("Do you have a user account on IREPS?")) {
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
    return "initial";
  }

  String getQuestionText(String questionKey) {
    switch (questionKey) {
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
        return "Hey! I'm your IREPS Assistant. How can I help you today?";
    }
  }

  List<String> getOptions() {
    if (currentQuestion == "subject" && queryType != null) {
      return subjectOptions[queryType!] ?? [];
    }
    if (currentQuestion == "zone" && organizationType != null) {
      return zoneOptions[organizationType!] ?? [];
    }
    switch (currentQuestion) {
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
      default:
        return [];
    }
  }

  void resetChat() {
    setState(() {
      messages.clear();
      _showTypingIndicator();

      Future.delayed(Duration(milliseconds: 300), () {
        setState(() {
          isTyping = false;
          messages.add({
            'bot': "Hey! I'm your IREPS Assistant. How can I help you today?",
            'timestamp': DateTime.now().toString(),
          });
          _scrollToBottom();

          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {
              isTyping = false;
              messages.add({
                'bot': "Do you have a user account on IREPS?",
                'timestamp': DateTime.now().toString(),
              });
              currentQuestion = "hasAccount";
              _scrollToBottom();
            });
          });
        });
      });
    });
  }

  void _showTypingIndicator() {
    setState(() {
      isTyping = true;
    });

    // Always scroll after showing typing indicator
    _scrollToBottom();
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

      // Force scroll after adding messages
      _scrollToBottom();
    });

    // Database operations
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
    // Add a small delay to ensure the UI has updated before scrolling
    Future.delayed(Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Add extra padding
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
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

    // Force scroll immediately after user's message
    _scrollToBottom();

    // Process the response with reduced delay
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

      // Force scroll again after processing response
      _scrollToBottom();
    });
  }

  void _delayedBotResponse(String message, int delay, {String? nextQuestion}) {
    _showTypingIndicator();

    // Reduce the delay to make responses appear faster
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

        // Force scroll immediately within this setState callback
        _scrollToBottom();
      });
    });
  }

  Future<void> processNextStep(String response) async {
    switch (currentQuestion) {
      case "hasAccount":
        hasIrepsAccount = response.toLowerCase() == "yes";
        _delayedBotResponse("Your email?", 700);
        currentQuestion = "email";
        break;
      case "email":
        if (_isValidEmail(response)) {
          userEmail = response; // Store user input email
          if (hasIrepsAccount!) {
            // User claims to have an account - try to fetch from database
            try {
              Map<String, dynamic>? userData =
                  await DatabaseHelper.instance.getUserByEmail(userEmail);
              if (userData != null) {
                // Found user in database - retrieve their info
                int userId = userData['id'];
                mobileNo = userData['mobile'] ?? "";
                userDepartment = userData['department'] ?? "";
                // Check department type to get additional details
                if (userDepartment == "Vendor/Contractor/Auction Bidder") {
                  // Get vendor details
                  List<Map<String, dynamic>> vendorData =
                      await DatabaseHelper.instance.query('vendor_details',
                          where: 'user_id = ?', whereArgs: [userId]);
                  if (vendorData.isNotEmpty) {
                    firmName = vendorData.first['firm_name'] ?? "";
                    UserName = vendorData.first['user_name'] ?? "";
                  }
                  // Show pre-registered details
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
                        ""; // Ensure we get designation
                  }
                  _delayedBotResponse(
                      "Your Registered Details are:\n"
                      " Email: $userEmail\n"
                      " Mobile No.: $mobileNo\n"
                      " Organization: $organizationType\n"
                      " Zone: $zone\n"
                      " Unit: $unit\n"
                      " Designation: $designation\n" // Include designation in display
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
          _delayedBotResponse("Your query?", 700);
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
                  "queryDescription" // Keep same question to allow retry
              );
        } else {
          queryDescription = response.trim();
          // Ask for confirmation in chat instead of dialog
          _delayedBotResponse("Do you want to submit this query?", 700,
              nextQuestion: "submitConfirmation");
        }
        break;
      case "submitConfirmation":
        if (response.toLowerCase() == "yes") {
          _generateQueryId(); // Generate ID and submit query
        } else {
          _delayedBotResponse(
              "Query submission cancelled. How can I help you further?", 700);
          resetChat(); // Reset the conversation
        }
        break;
      case "attachDocuments":
        if (response.toLowerCase() == "yes") {
          // Navigate to Attach Documents Page with slide-from-bottom animation
          Navigator.push(
            context,
            SlidePageRoute(
              page: AttachDocumentsPage(queryId: _queryId),
              direction: AxisDirection.up, // <-- slide from bottom
            ),
          ).then((_) {
            _delayedBotResponse(
              "Thank you! Your query has been recorded.",
              700,
            );
            currentQuestion = "initial"; // Reset to initial state
          });
        } else {
          _delayedBotResponse(
            "Thank you! Your query has been recorded.",
            700,
          );
          currentQuestion = "initial"; // Reset here as no next question needed
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
        r'^[6-9]\d{9}$'); // Matches exactly 10-digit numbers starting with 6-9
    return regex.hasMatch(mobile) && mobile.length == 10;
  }

  bool _isValidUserName(String UserName) {
    final RegExp regex =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9 _@#\$%\^\&\*\(\)\-]{2,19}$');
    return regex.hasMatch(UserName);
  }

  Widget build(BuildContext context) {
    void clearCurrentAnswer() {
      setState(() {
        userInputController.clear();
      });
    }

    userInputController.clear();
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
                    direction: AxisDirection.up, // or left, right, down
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: List.generate(messages.length, (index) {
                          bool isBot = messages[index].containsKey('bot');
                          // Check if this message is the first in a sequence from the same sender
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
                                    // : Color(0xFFA0D6CE),
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
                                            right:
                                                45), // leave space for timestamp
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

                              // Replace the existing options rendering code with this improved version
                              if (isBot &&
                                  index == messages.length - 1 &&
                                  getOptions().isNotEmpty)
                                (() {
                                  List<String> options = getOptions();
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: options.map((option) {
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            onTap: () =>
                                                handleUserResponse(option),
                                            splashColor: Color(0xFF075E54)
                                                .withOpacity(0.2),
                                            highlightColor: Color(0xFF075E54)
                                                .withOpacity(0.1),
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                    color: Color(0xFF075E54),
                                                    width: 1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    spreadRadius: 1,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                child: Text(
                                                  option,
                                                  style: TextStyle(
                                                    color: Color(0xFF075E54),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                })(),
                            ],
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (messages.isNotEmpty &&
                messages.last.containsKey('bot') &&
                getOptions().isEmpty)
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
                                maxLength:
                                    currentQuestion == "mobileNo" ? 10 : null,
                                keyboardType: currentQuestion == "mobileNo"
                                    ? TextInputType.number
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: currentQuestion == "mobileNo"
                                      ? "Enter your 10-digit mobile number..."
                                      : "Type your message...",
                                  hintStyle: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 14),
                                  counterText:
                                      currentQuestion == "mobileNo" ? "" : null,
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
                                onPressed: clearCurrentAnswer,
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
  return DateFormat('EEEE, MMMM d').format(date); // e.g., Monday, May 5
}
