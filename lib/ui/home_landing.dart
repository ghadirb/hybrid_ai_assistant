
import 'package:flutter/material.dart';
import 'model_selector.dart';
import 'chat_page.dart';
import 'backup_page.dart';

class HomeLandingPage extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('دستیار هوشمند')), body: Padding(padding: EdgeInsets.all(16), child: ListView(children:[
      Card(child: ListTile(leading: Icon(Icons.offline_bolt,size:40,color:Colors.blue), title: Text("حالت آفلاین"), subtitle: Text("دانلود و فعال‌سازی مدل محلی"), trailing: Icon(Icons.arrow_forward_ios), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => ModelSelectorPage())))),
      SizedBox(height:12),
      Card(child: ListTile(leading: Icon(Icons.backup,size:40,color:Colors.orange), title: Text("پشتیبان‌گیری و بازیابی"), subtitle: Text("بک‌آپ گرفتن و بازگردانی از Google Drive"), trailing: Icon(Icons.arrow_forward_ios), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => BackupPage())))),
      SizedBox(height:12),
      ElevatedButton.icon(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage())), icon: Icon(Icons.chat), label: Text("باز کردن چت"))
    ])));
  }
}
