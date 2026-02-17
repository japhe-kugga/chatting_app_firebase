import 'package:chatting_app_firebase/components/chat_bubble.dart';
import 'package:chatting_app_firebase/components/my_textfield.dart';
import 'package:chatting_app_firebase/services/auth_service.dart';
import 'package:chatting_app_firebase/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatting_app_firebase/main.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with RouteAware {
  // text controller
  final TextEditingController _messageController = TextEditingController();

  // chat & auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // for textfield focus
  FocusNode myFocusNode = FocusNode();

  Color? _backgroundColor;

  @override
  void initState() {
    super.initState();

    // load chat background preference from local storage first for speed
    _loadChatBackgroundColor();

    // add listener to focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        // then the amount of remaining space will be calculated,
        // then scroll down (only if controller is attached)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_scrollController.hasClients) scrollDown();
        });
      }
    });

    // wait a bit for listview to be built, then scroll to bottom
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_scrollController.hasClients) scrollDown();
    });

    // Mark all unread messages from the receiver as seen
    _markUnreadMessagesAsSeen();
  }

  // load saved chat background color from SharedPreferences
  Future<void> _loadChatBackgroundColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('chatBackgroundColor');
      if (colorValue != null && mounted) {
        setState(() {
          _backgroundColor = Color(colorValue);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Refresh background color when returning from settings
    _loadChatBackgroundColor();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    if (!_scrollController.hasClients) return;
    try {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    } catch (e) {
      // ignore animation errors when layout isn't ready
    }
  }

  // Mark unread messages from receiver as seen
  Future<void> _markUnreadMessagesAsSeen() async {
    String currentUserId = _authService.getCurrentUser()!.uid;

    // Get messages and mark unread ones as seen
    List<String> ids = [widget.receiverID, currentUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        await _chatService.markMessageAsSeen(
          doc.id,
          currentUserId,
          widget.receiverID,
        );
      }
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  // send message
  void sendMessage() async {
    // only send message if there is something to send
    if (_messageController.text.isNotEmpty) {
      // send the message
      await _chatService.sendMessage(
          widget.receiverID, _messageController.text);

      // clear the text controller
      _messageController.clear();

      // scroll to bottom after a delay to let Firestore update
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
        stream: _chatService.getChatBackgroundColorStream(),
        builder: (context, snapshot) {
          // If snapshot has data, it means Firestore has loaded. Update local state if needed (optional)
          // But mainly we use it to construct the UI
          if (snapshot.hasData && snapshot.data != null) {
            _backgroundColor = Color(snapshot.data!);
          }

          return Scaffold(
            backgroundColor:
                _backgroundColor ?? Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(widget.receiverEmail),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.grey,
            ),
            body: Column(
              children: [
                // messages
                Expanded(
                  child: _buildMessageList(),
                ),

                // user input
                _buildUserInput(),
              ],
            ),
          );
        });
  }

  // build message list
  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        // errors
        if (snapshot.hasError) {
          return const Text("Error");
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });

        // return list view
        return ListView(
          controller: _scrollController,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // is current user
    bool isCurrentUser = data['senderId'] == _authService.getCurrentUser()!.uid;

    // align message to the right if sender is the current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    // get isSeen status
    bool isSeen = data['isSeen'] ?? false;

    // get timestamp
    Timestamp? timestamp = data['timestamp'] as Timestamp?;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
            isSeen: isSeen,
            timestamp: timestamp,
          ),
        ],
      ),
    );
  }

  // build message input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        children: [
          // textfield should take up most of the space
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),

          // send button
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
