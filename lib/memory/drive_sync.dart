
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DriveSync {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope]);

  static Future<GoogleSignInAccount?> signInInteractive() => _googleSignIn.signIn();
  static Future<void> signOut() => _googleSignIn.signOut();
  static Future<bool> isSignedIn() async {
    final user = await _googleSignIn.signInSilently();
    return user != null;
  }

  static Future<drive.FileList> listBackups() async {
    final user = await _googleSignIn.signInSilently();
    if (user == null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    final files = await driveApi.files.list(spaces: 'appDataFolder', orderBy: 'createdTime desc');
    return files;
  }

  static Future<void> backupDatabase() async {
    final user = await _googleSignIn.signInSilently();
    if (user == null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    final dbPath = join(await getDatabasesPath(), 'memory.db');
    final f = File(dbPath);
    if (!f.existsSync()) throw Exception('Local DB not found');
    final driveFile = drive.File()..name = "memory.db.\${DateTime.now().toIso8601String()}"..parents = ["appDataFolder"];
    final media = drive.Media(f.openRead(), f.lengthSync());
    await driveApi.files.create(driveFile, uploadMedia: media);
  }

  static Future<void> restoreLatestDatabase() async {
    final user = await _google_sign_in.signInSilently();
    if (user == null) throw Exception('Not signed in');
    final authHeaders = await user.authHeaders;
    final client = _GoogleHttpClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    final files = await driveApi.files.list(spaces: 'appDataFolder', orderBy: 'createdTime desc', pageSize: 10);
    if (files.files==null || files.files!.isEmpty) throw Exception('No backup files on Drive');
    final latest = files.files!.first;
    final media = await driveApi.files.get(latest.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final data = <int>[];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    final tmp = File(join(await getDatabasesPath(), 'memory.db.restore.tmp'));
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
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
  @override void close() => _inner.close();
}
