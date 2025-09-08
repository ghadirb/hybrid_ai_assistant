
import 'package:flutter/material.dart';
import '../memory/drive_sync.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class BackupPage extends StatefulWidget {
  @override _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool loading = false;
  String message = "";
  List<drive.File>? backups;

  Future<void> _signIn() async {
    setState(()=> loading=true);
    try {
      final acc = await DriveSync.signInInteractive();
      setState(()=> message = acc!=null ? 'Signed in as ${acc!.email}' : 'Sign in cancelled');
    } catch (e) {
      setState(()=> message = 'Sign in error: $e');
    } finally { setState(()=> loading=false); }
  }

  Future<void> _listBackups() async {
    setState(()=> loading=true);
    try {
      final files = await DriveSync.listBackups();
      setState(()=> backups = files.files);
    } catch (e) { setState(()=> message = 'List error: $e'); }
    finally { setState(()=> loading=false); }
  }

  Future<void> _backup() async {
    setState(()=> loading=true);
    try {
      await DriveSync.backupDatabase();
      setState(()=> message = 'Backup uploaded');
      await _listBackups();
    } catch (e) { setState(()=> message = 'Backup error: $e'); } finally { setState(()=> loading=false); }
  }

  Future<void> _restoreLatest() async {
    setState(()=> loading=true);
    try {
      await DriveSync.restoreLatestDatabase();
      setState(()=> message = 'Restore completed. Restart app.');
    } catch (e) { setState(()=> message = 'Restore error: $e'); } finally { setState(()=> loading=false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Backup & Restore')), body: Padding(
      padding: EdgeInsets.all(16), 
      child: Column(children: [
        ElevatedButton(child: Text('Sign in with Google'), onPressed: _signIn),
        SizedBox(height:12),
        ElevatedButton(child: Text('Backup DB'), onPressed: _backup),
        SizedBox(height:12),
        ElevatedButton(child: Text('List backups'), onPressed: _listBackups),
        SizedBox(height:12),
        ElevatedButton(child: Text('Restore latest'), onPressed: _restoreLatest),
        SizedBox(height:12),
        if (loading) CircularProgressIndicator(),
        Text(message),
        if (backups!=null) Expanded(child: ListView(children: backups!.map((f)=>ListTile(title: Text(f.name??'no-name'), subtitle: Text(f.id??''))).toList()))
      ])
    ));
  }
}
