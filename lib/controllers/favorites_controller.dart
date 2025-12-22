// lib/controllers/favorites_controller.dart

import 'package:get/get.dart';
import 'package:thort_jivit/services/favorite_storage_service.dart';

class FavoritesController extends GetxController {
  // Observable set of favorite video IDs
  final RxSet<String> favoriteIds = <String>{}.obs;
  
  // Check if a video is favorited
  bool isFavorite(String videoId) {
    return favoriteIds.contains(videoId);
  }
  
  // Load favorites from storage
  Future<void> loadFavorites() async {
    try {
      final ids = await FavoriteStorageService.getFavoriteIds();
      favoriteIds.clear();
      favoriteIds.addAll(ids);
      print('[FAVORITES_CONTROLLER] ✅ Loaded ${ids.length} favorites: $ids');
    } catch (e) {
      print('[FAVORITES_CONTROLLER] ❌ Error loading favorites: $e');
    }
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(String videoId) async {
    try {
      final currentlyFavorite = favoriteIds.contains(videoId);
      
      if (currentlyFavorite) {
        // Remove from favorites
        favoriteIds.remove(videoId);
        await FavoriteStorageService.removeFavorite(videoId);
        print('[FAVORITES_CONTROLLER] ❤️ Removed favorite: $videoId');
      } else {
        // Add to favorites
        favoriteIds.add(videoId);
        await FavoriteStorageService.addFavorite(videoId);
        print('[FAVORITES_CONTROLLER] ❤️ Added favorite: $videoId');
      }
      
      // Update is automatic via GetX reactivity
      print('[FAVORITES_CONTROLLER] 📂 Current favorites: $favoriteIds');
    } catch (e) {
      print('[FAVORITES_CONTROLLER] ❌ Error toggling favorite: $e');
      // Revert on error
      if (favoriteIds.contains(videoId)) {
        favoriteIds.remove(videoId);
      } else {
        favoriteIds.add(videoId);
      }
    }
  }
  
  // Clear all favorites
  Future<void> clearAll() async {
    try {
      favoriteIds.clear();
      await FavoriteStorageService.clearAllFavorites();
      print('[FAVORITES_CONTROLLER] 🗑️ Cleared all favorites');
    } catch (e) {
      print('[FAVORITES_CONTROLLER] ❌ Error clearing favorites: $e');
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }
}

