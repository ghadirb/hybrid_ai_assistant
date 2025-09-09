
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../memory/local_db.dart';
import 'package:flutter/services.dart';

class ChatMessage { final String text; final String? audioPath; final bool isUser; final DateTime timestamp; ChatMessage({required this.text, this.audioPath, required this.isUser, required this.timestamp}); }

class ChatPage extends StatefulWidget { @override _ChatPageState createState() => _ChatPageState(); }
class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Record _recorder = Record();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String? _currentRecordingPath;
  static const platform = MethodChannel('hybrid_ai/engine');

  @override void initState(){ super.initState(); _loadMessages(); }
  @override void dispose(){ _player.dispose(); _recorder.dispose(); super.dispose(); }

  Future<void> _loadMessages() async {
    final rows = await LocalMemoryDB.getMessages();
    _messages.clear();
    for (final r in rows) {
      _messages.add(ChatMessage(text: r['text']??'', audioPath: r['audio_path'], isUser: (r['is_user']??0)==1, timestamp: DateTime.fromMillisecondsSinceEpoch(r['ts']??0)));
    }
    _scrollToBottom();
  }

  void _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    setState(()=> _messages.add(msg));
    await LocalMemoryDB.addMessage(text, "", true);
    _controller.clear(); _scrollToBottom();
    Future.delayed(Duration(milliseconds:500), () async {
      final replyText = "پاسخ نمونه: $text";
      setState(()=> _messages.add(ChatMessage(text: replyText, isUser: false, timestamp: DateTime.now())));
      await LocalMemoryDB.addMessage(replyText, "", false);
      _scrollToBottom();
    });
  }

  void _scrollToBottom(){ Future.delayed(Duration(milliseconds:100), () { try{ if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds:300), curve: Curves.easeOut); }catch(e){} }); }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      setState(()=> _isRecording = false);
      final path = _currentRecordingPath;
      if (path != null) {
        try {
          final res = await platform.invokeMethod('recognizeFile', {'path': path});
          final text = res?.toString() ?? '';
          if (text.isNotEmpty) {
            await LocalMemoryDB.addMessage(text, "", true);
            setState(()=> _messages.add(ChatMessage(text: text, audioPath: null, isUser: true, timestamp: DateTime.now())));
            _scrollToBottom();
            Future.delayed(Duration(milliseconds:400), () async {
              final replyText = "پاسخ (آفلاین/نمونه) به: $text";
              setState(()=> _messages.add(ChatMessage(text: replyText, isUser: false, timestamp: DateTime.now())));
              await LocalMemoryDB.addMessage(replyText, "", false);
              _scrollToBottom();
            });
          } else {
            await LocalMemoryDB.addMessage("", path, true);
            setState(()=> _messages.add(ChatMessage(text: "", audioPath: path, isUser: true, timestamp: DateTime.now())));
            _scrollToBottom();
          }
        } catch (e) {
          await LocalMemoryDB.addMessage("", path, true);
          setState(()=> _messages.add(ChatMessage(text: "", audioPath: path, isUser: true, timestamp: DateTime.now())));
          _scrollToBottom();
        }
      }
      _currentRecordingPath = null;
    } else {
      bool hasPerm = await Record.hasPermission();
      if (!hasPerm) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("مجوز میکروفون لازم است")));
        return;
      }
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = filePath;
      await _recorder.start(path: filePath, encoder: AudioEncoder.wav, bitRate: 128000, samplingRate: 16000);
      setState(()=> _isRecording = true);
    }
  }

  Future<void> _play(String path) async {
    try {
      await _player.setFilePath(path);
      _player.play();
    } catch (e) { print("play error: $e"); }
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final align = msg.isUser? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = msg.isUser? Colors.blue[400] : Colors.grey[200];
    final txtColor = msg.isUser? Colors.white : Colors.black87;
    return Column(crossAxisAlignment: align, children: [
      Container(margin: EdgeInsets.symmetric(vertical:4,horizontal:8), padding: EdgeInsets.all(10), decoration: BoxDecoration(color:bg,borderRadius: BorderRadius.circular(12)), child: msg.audioPath==null ? Text(msg.text, style: TextStyle(color: txtColor, fontSize:16)) : Row(children: [ Icon(Icons.mic, color: txtColor), SizedBox(width:6), Text("پیام صوتی", style: TextStyle(color: txtColor)), IconButton(icon: Icon(Icons.play_arrow, color: txtColor), onPressed: () => _play(msg.audioPath!)) ])),
      Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text(DateFormat.Hm().format(msg.timestamp), style: TextStyle(fontSize:12,color:Colors.grey[600])))
    ]);
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text("گفت‌وگو با دستیار")), body: Column(children:[ Expanded(child: ListView.builder(controller: _scrollController, itemCount: _messages.length, itemBuilder: (c,i){ final m = _messages[i]; return Align(alignment: m.isUser? Alignment.centerRight: Alignment.centerLeft, child: _buildMessageBubble(m)); })), Divider(height:1), Container(padding: EdgeInsets.symmetric(horizontal:8,vertical:4), color: Colors.white, child: Row(children:[ Expanded(child: TextField(controller: _controller, decoration: InputDecoration.collapsed(hintText: "پیام خود را بنویسید..."))), IconButton(icon: Icon(Icons.send, color: Colors.blue), onPressed: _sendTextMessage), IconButton(icon: Icon(_isRecording? Icons.stop : Icons.mic, color: Colors.redAccent), onPressed: _toggleRecording), ])) ]));
  }
}
