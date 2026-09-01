import 'package:flutter/material.dart';
import '../data/disease_info.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  const _ChatMessage(this.text, this.fromUser);
}

/// Conversational AI Treatment Assistant (report Section 4.2.3, Figure 4.4).
/// Opens greeting the farmer with the diagnosed disease and confidence
/// already in context, offers suggested follow-up questions, and accepts
/// free text through a chat input field.
class AiTreatmentAssistantScreen extends StatefulWidget {
  final String diseaseKey;
  final double confidence;

  const AiTreatmentAssistantScreen({
    super.key,
    required this.diseaseKey,
    required this.confidence,
  });

  @override
  State<AiTreatmentAssistantScreen> createState() => _AiTreatmentAssistantScreenState();
}

class _AiTreatmentAssistantScreenState extends State<AiTreatmentAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final DiseaseInfo _info;

  @override
  void initState() {
    super.initState();
    _info = diseaseInfoByKey[widget.diseaseKey] ??
        diseaseInfoByKey['Healthy_Leaves']!;
    _messages.add(_ChatMessage(
      "Hello! I'm your coconut disease expert. Your tree has been diagnosed "
      "with ${_info.label}. How can I help you with the treatment?",
      false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(trimmed, true));
      _messages.add(_ChatMessage(answerTreatmentQuestion(_info, trimmed), false));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Treatment Assistant'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.confirmed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_info.label} · ${(widget.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: AppColors.confirmed, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Text('Ask me anything about treatment',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              // Suggested-question chips are rendered inside item 0's own
              // cell below (not as a separate list item) — inflating
              // itemCount to "make room" for them made ListView.builder
              // call itemBuilder(context, 1) even with only one message,
              // which then indexed _messages[1] on a 1-element list.
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bubble(_messages[0]),
                      const SizedBox(height: 12),
                      if (_messages.length == 1) _suggestedQuestions(),
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _bubble(_messages[index]),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _suggestedQuestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestedTreatmentQuestions.map((q) {
        return GestureDetector(
          onTap: () => _send(q),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.primary.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(q, style: const TextStyle(color: AppColors.primaryGlow, fontSize: 12.5)),
          ),
        );
      }).toList(),
    );
  }

  Widget _bubble(_ChatMessage message) {
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.fromUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.eco_rounded, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.fromUser ? AppColors.primary : const Color(0xFF1D1D1D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        color: const Color(0xFF0A0A0A),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a question...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(_controller.text),
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
