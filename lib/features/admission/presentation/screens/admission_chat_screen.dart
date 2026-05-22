import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/supabase_provider.dart';

/// Sprint 2.1D — public-facing admissions chat screen.
///
/// Parents arrive anonymously (no auth). The screen persists a session UUID
/// in SharedPreferences so refreshes don't lose the conversation. Each
/// outgoing message hits the `admission-faq-chat` edge function which does
/// RAG over the tenant's `admission_faqs` and returns an AI-generated reply.
///
/// Route: /admissions/chat?tenantId=<uuid>  (constructor takes tenantId).
class AdmissionChatScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String? schoolName;

  const AdmissionChatScreen({
    super.key,
    required this.tenantId,
    this.schoolName,
  });

  @override
  ConsumerState<AdmissionChatScreen> createState() =>
      _AdmissionChatScreenState();
}

class _AdmissionChatScreenState
    extends ConsumerState<AdmissionChatScreen> {
  static const _sessionKeyPrefix = 'admission_chat_session_';
  static const _historyKeyPrefix = 'admission_chat_history_';

  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  final List<_ChatMessage> _messages = [];

  String? _sessionId;
  bool _busy = false;
  bool _rateLimited = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sKey = '$_sessionKeyPrefix${widget.tenantId}';
    final hKey = '$_historyKeyPrefix${widget.tenantId}';
    var id = prefs.getString(sKey);
    if (id == null) {
      id = _generateSessionId();
      await prefs.setString(sKey, id);
    }
    final historyJson = prefs.getString(hKey);
    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List;
        _messages.addAll(list
            .whereType<Map>()
            .map((m) => _ChatMessage.fromJson(m.cast<String, dynamic>())));
      } catch (_) {/* ignore corrupt cache */}
    }
    if (mounted) setState(() => _sessionId = id);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final hKey = '$_historyKeyPrefix${widget.tenantId}';
    final json = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(hKey, json);
  }

  Future<void> _send() async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty || _busy || _sessionId == null) return;

    setState(() {
      _busy = true;
      _rateLimited = false;
      _messages.add(_ChatMessage(role: 'user', content: text));
      _inputCtl.clear();
    });
    _scrollToBottom();

    try {
      final SupabaseClient client = ref.read(supabaseProvider);
      final res = await client.functions.invoke(
        'admission-faq-chat',
        body: {
          'session_id': _sessionId,
          'tenant_id': widget.tenantId,
          'question': text,
        },
      );

      if (res.status == 429) {
        setState(() {
          _rateLimited = true;
          _messages.add(_ChatMessage(
            role: 'assistant',
            content:
                'I\'ve answered a lot of questions in a short window — please try again in a few minutes, or call the admissions office.',
          ));
        });
        return;
      }

      if (res.status != 200 || res.data is! Map) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content:
                'Sorry, I couldn\'t reach the assistant just now. Please try again in a moment.',
          ));
        });
        return;
      }

      final data = (res.data as Map).cast<String, dynamic>();
      final reply = (data['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content:
                'I don\'t have an answer to that yet. Please call the admissions office.',
          ));
        });
        return;
      }
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: reply,
          isFallback: data['fallback_used'] == true,
        ));
      });
      await HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content:
              'Connection issue. Check your internet and try again — or call the admissions office.',
        ));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      await _persistHistory();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtl.hasClients) return;
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final school = widget.schoolName ?? 'our school';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admissions Assistant'),
            Text(
              'Asking about $school',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_messages.isEmpty && !_busy)
            Expanded(child: _EmptyHero(schoolName: school)),
          if (_messages.isNotEmpty || _busy)
            Expanded(
              child: ListView.builder(
                controller: _scrollCtl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length && _busy) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: _messages[i]);
                },
              ),
            ),
          if (_rateLimited)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: scheme.errorContainer,
              child: Text(
                'Rate limit reached. Please wait a few minutes before sending more.',
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
              ),
            ),
          _Composer(
            controller: _inputCtl,
            onSubmit: _send,
            busy: _busy,
          ),
        ],
      ),
    );
  }

  // Cheap UUID-shaped id. We don't need cryptographic strength — server hashes
  // IP separately for rate-limit; session id is correlation-only.
  String _generateSessionId() {
    final rnd = Random.secure();
    String hex(int n) {
      final buf = StringBuffer();
      for (var i = 0; i < n; i++) {
        buf.write(rnd.nextInt(16).toRadixString(16));
      }
      return buf.toString();
    }
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${hex(4)}-${hex(12)}';
  }
}

// ---------------------------------------------------------------------------
// Local message model
// ---------------------------------------------------------------------------

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final bool isFallback;
  final DateTime at;

  _ChatMessage({
    required this.role,
    required this.content,
    this.isFallback = false,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory _ChatMessage.fromJson(Map<String, dynamic> j) => _ChatMessage(
        role: j['role'] as String,
        content: j['content'] as String,
        isFallback: (j['fallback'] as bool?) ?? false,
        at: DateTime.tryParse(j['at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'fallback': isFallback,
        'at': at.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// UI bits
// ---------------------------------------------------------------------------

class _EmptyHero extends StatelessWidget {
  final String schoolName;
  const _EmptyHero({required this.schoolName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 32, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            'Ask anything about admissions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fees, dates, eligibility, documents required, '
            'campus visits — I\'ll do my best to answer from $schoolName\'s '
            'published policies.',
            style: TextStyle(
              fontSize: 14,
              height: 1.43,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Answers come from $schoolName\'s FAQs. For policy decisions, '
              'fee disputes, or anything urgent, please call the admissions '
              'office directly.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == 'user';
    final bg = isUser ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isUser ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(color: fg, fontSize: 14, height: 1.43),
            ),
            if (!isUser) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.isFallback ? 'AI (backup)' : 'AI',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Semantics(
          label: 'Assistant is typing',
          liveRegion: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thinking…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool busy;

  const _Composer({
    required this.controller,
    required this.onSubmit,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: busy
                      ? 'Waiting for assistant…'
                      : 'Ask about fees, dates, eligibility…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send'),
              onPressed: busy ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
