import 'package:flutter/material.dart';

class JambooAIScreen extends StatefulWidget {
  const JambooAIScreen({super.key});

  @override
  State<JambooAIScreen> createState() => _JambooAIScreenState();
}

class _JambooAIScreenState extends State<JambooAIScreen> {
  final TextEditingController _controller = TextEditingController();
bool isTyping = false;
  final List<Map<String, dynamic>> messages = [
    {
      "text":
          "👋 Hi! Main Jamboo AI hoon.\n\n"
          "Mujhe apna mood ya budget batao, main best food recommend karunga.\n\n"
          "✨ Main kya kar sakta hoon?\n\n"
          "🍽️ Mood ke hisaab se food recommend karta hoon\n"
          "💰 Budget ke andar best options dhoondhta hoon\n"
          "👨‍👩‍👧‍👦 Family aur Party combos suggest karta hoon\n"
          "⚡ Fast delivery wale restaurants batata hoon\n\n"
          "👇 Neeche diye gaye Quick Suggestions se shuruaat karein.",
      "isUser": false,
    },
  ];

  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "text": _controller.text,
        "isUser": true,
      });

     
    });
setState(() {
  isTyping = true;
});

await Future.delayed(const Duration(seconds: 2));

setState(() {
  isTyping = false;

  messages.add({
    "text": "🤖 Thanks! Jaldi hi main smart recommendation dunga.",
    "isUser": false,
  });
});
    _controller.clear();
  }

Widget suggestionChip(String text) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      _controller.text = text;
      sendMessage();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.shade200,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                "assets/images/jamboo_avatar.png",
                width: 105,
                height: 105,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Jamboo AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                if (index == 0) {
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets.all(14),
                          constraints:
                              const BoxConstraints(
                            maxWidth: 330,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    15),
                          ),
                          child: Text(
                            msg["text"],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("💸 Under ₹200"),
    ),
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("🥗 Healthy"),
    ),
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("😋 Tasty & Healthy"),
    ),
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("👨‍👩‍👧‍👦 Family Pack"),
    ),
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("🎉 Party Vibe"),
    ),
    SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: suggestionChip("🎁 Surprise Me"),
    ),
  ],
),

                      const SizedBox(height: 20),
                    ],
                  );
                }

                return Align(
                  alignment: msg["isUser"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(14),
                    constraints:
                        const BoxConstraints(
                      maxWidth: 280,
                    ),
                    decoration: BoxDecoration(
                      color: msg["isUser"]
                          ? Colors.deepPurple
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: msg["isUser"]
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
if (isTyping)
  const Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 8,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "🤖 Jamboo AI is typing...",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask Jamboo AI...",
                      filled: true,
                      fillColor:
                          Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Colors.deepPurple,
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
],
            ),
          ),
        ],
      ),
    );
  }
}