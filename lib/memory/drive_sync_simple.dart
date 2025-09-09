
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DriveSyncSimple {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope]);

  static Future<GoogleSignInAccount?> signInInteractive() => _googleSignIn.signIn();
  static Future<drive.FileList> listBackups() async {
    final user = await _googleSignIn.signInSilently();
    if (user==null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    return await driveApi.files.list(spaces: 'appDataFolder', orderBy: 'createdTime desc');
  }

  static Future<void> backupDatabase() async {
    final user = await _googleSignIn.signInSilently();
    if (user==null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    final dbPath = join(await getDatabasesPath(), 'memory.db');
    final f = File(dbPath);
    if (!f.existsSync()) throw Exception('Local DB not found');
    final driveFile = drive.File()..name = "memory.db.${DateTime.now().toIso8601String()}"..parents = ["appDataFolder"];
    final media = drive.Media(f.openRead(), f.lengthSync());
    await driveApi.files.create(driveFile, uploadMedia: media);
  }

  static Future<void> restoreFileById(String id) async {
    final user = await _googleSignIn.signInSilently();
    if (user==null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    final media = await driveApi.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final data = <int>[];
    await for (final chunk in media.stream) { data.addAll(chunk); }
    final tmpPath = join(await getDatabasesPath(), 'memory.db.restore.tmp');
    final tmp = File(tmpPath);
    tmp.writeAsBytesSync(data);
    final dest = File(join(await getDatabasesPath(), 'memory.db'));
    if (dest.existsSync()) dest.deleteSync();
    tmp.renameSync(dest.path);
  }
}

class _GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _GoogleHttpClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) { request.headers.addAll(_headers); return _inner.send(request); }
  @override void close() => _inner.close();
}
