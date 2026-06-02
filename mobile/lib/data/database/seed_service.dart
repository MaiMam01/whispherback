import '../repositories/playlist_repository.dart';
import 'database_helper.dart';

/// Seeds demo playlists on first launch (no fake audio paths — add clips via Record/Import).
class SeedService {
  static Future<void> seedIfEmpty() async {
    final db = DatabaseHelper.instance;
    final playlistRepo = PlaylistRepository(db);

    final playlists = await playlistRepo.getAll();
    if (playlists.isNotEmpty) return;

    await playlistRepo.create('Morning Whispers');
    await playlistRepo.create('Work Focus');
  }
}
