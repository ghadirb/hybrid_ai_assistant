
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
class ModelSelectorPage extends StatefulWidget { @override _ModelSelectorPageState createState() => _ModelSelectorPageState(); }
class _ModelSelectorPageState extends State<ModelSelectorPage> {
  bool downloading=false; double progress=0.0; String activeModelPath="";
  final models = { "English small (vosk-model-small-en-us-0.15)": "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip" };
  @override void initState(){ super.initState(); _loadActive(); }
  Future<void> _loadActive() async { final prefs = await SharedPreferences.getInstance(); setState(()=> activeModelPath = prefs.getString("vosk_model_path") ?? ""); }
  Future<void> downloadAndExtract(String url) async {
    setState(()=>{ downloading=true, progress=0.0 });
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory("${dir.path}/models");
    if (!modelsDir.existsSync()) modelsDir.createSync(recursive:true);
    final tmpZip = File("${modelsDir.path}/temp.zip");
    final dio = Dio();
    await dio.download(url, tmpZip.path, onReceiveProgress: (rec,total){ setState(()=> progress = total!=0? rec/total:0.0); });
    try {
      final bytes = tmpZip.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final outPath = "${modelsDir.path}/${file.name}";
        if (file.isFile) { File(outPath).createSync(recursive:true); File(outPath).writeAsBytesSync(file.content as List<int>); } else { Directory(outPath).createSync(recursive:true); }
      }
      tmpZip.deleteSync();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("vosk_model_path", modelsDir.path + "/vosk-model-small-en-us-0.15");
      setState(()=> activeModelPath = prefs.getString("vosk_model_path") ?? "");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("مدل دانلود و نصب شد")));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطا در اکسترکت: \$e"))); }
    setState(()=>{ downloading=false, progress=0.0 });
  }
  @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: Text("مدیریت مدل‌های آفلاین")), body: Padding(padding: EdgeInsets.all(16), child: downloading? Column(mainAxisAlignment: MainAxisAlignment.center, children:[ CircularProgressIndicator(value:progress), SizedBox(height:12), Text("در حال دانلود ${(progress*100).toStringAsFixed(0)}%") ]) : Column(children:[ Text("مدل فعال: ${activeModelPath.isEmpty? 'هنوز تنظیم نشده' : activeModelPath}"), SizedBox(height:12), Expanded(child: ListView(children: models.entries.map((e)=> ListTile(title: Text(e.key), subtitle: Text(e.value), trailing: Icon(Icons.download), onTap: ()=> downloadAndExtract(e.value))).toList())) ]))); }
}
