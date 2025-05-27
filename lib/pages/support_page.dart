import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupportPage extends StatefulWidget {
  final List<Map<String, String>> chatMessages;

  const SupportPage({super.key, required this.chatMessages});

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _suggestionsScrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        widget.chatMessages.add({
          'text': _controller.text,
          'sender': 'user',
          'time': DateFormat('HH:mm').format(DateTime.now()),
        });

        _controller.clear();
        _focusNode.unfocus();

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            widget.chatMessages.add({
              'text': 'Спасибо за ваше сообщение! Мы свяжемся с вами в ближайшее время.',
              'sender': 'support',
              'time': DateFormat('HH:mm').format(DateTime.now()),
            });
          });
          _scrollToBottom();
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(text: 'Ec', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'o', style: TextStyle(color: Colors.red)),
              TextSpan(text: 'Tech', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'B', style: TextStyle(color: Colors.green)),
              TextSpan(text: 'in', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // История сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: widget.chatMessages.length,
              itemBuilder: (context, index) {
                final message = widget.chatMessages[index];
                final isUser = message['sender'] == 'user';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: 
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? Colors.green[600]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text']!,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['time']!,
                              style: TextStyle(
                                color: isUser 
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Быстрые подсказки с горизонтальным скроллом
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              controller: _suggestionsScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSuggestionChip('Маршрут', Icons.directions, Colors.green[700]!),
                  _buildSuggestionChip('Техника', Icons.build, Colors.orange[700]!),
                  _buildSuggestionChip('GPS', Icons.gps_fixed, Colors.blue[700]!),
                  _buildSuggestionChip('Бак', Icons.delete, Colors.purple[700]!),
                  _buildSuggestionChip('Ошибка', Icons.error, Colors.red[700]!),
                  _buildSuggestionChip('Другое', Icons.help, Colors.grey[700]!),
                ],
              ),
            ),
          ),

          // Поле ввода сообщения
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Напишите ваш вопрос...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[700]!,
                        Colors.lightGreen[400]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        avatar: Icon(icon, size: 18, color: Colors.white),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        onPressed: () {
          _controller.text = '$text: ';
          _focusNode.requestFocus();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _suggestionsScrollController.dispose();
    super.dispose();
  }
}