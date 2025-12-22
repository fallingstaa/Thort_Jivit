// lib/services/favorite_storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for storing favorites locally (no Firebase)
class FavoriteStorageService {
  static const String _favoritesKey = 'user_favorites';
  
  /// Get all favorite video IDs
  static Future<Set<String>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return <String>{};
      }
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      return favoritesList.map((e) => e.toString()).toSet();
    } catch (e) {
      print('[FAVORITES_STORAGE] Error loading favorites: $e');
      return <String>{};
    }
  }
  
  /// Check if a video is favorited
  static Future<bool> isFavorite(String videoId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(videoId);
  }
  
  /// Add a video to favorites
  static Future<bool> addFavorite(String videoId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.add(videoId);
      return await _saveFavorites(favorites);
    } catch (e) {
      print('[FAVORITES_STORAGE] Error adding favorite: $e');
      return false;
    }
  }
  
  /// Remove a video from favorites
  static Future<bool> removeFavorite(String videoId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.remove(videoId);
      return await _saveFavorites(favorites);
    } catch (e) {
      print('[FAVORITES_STORAGE] Error removing favorite: $e');
      return false;
    }
  }
  
  /// Toggle favorite status
  static Future<bool> toggleFavorite(String videoId) async {
    final isFav = await isFavorite(videoId);
    if (isFav) {
      return await removeFavorite(videoId);
    } else {
      return await addFavorite(videoId);
    }
  }
  
  /// Save favorites to local storage
  static Future<bool> _saveFavorites(Set<String> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = favorites.toList();
      final favoritesJson = json.encode(favoritesList);
      return await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('[FAVORITES_STORAGE] Error saving favorites: $e');
      return false;
    }
  }
  
  /// Clear all favorites
  static Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      print('[FAVORITES_STORAGE] Error clearing favorites: $e');
      return false;
    }
  }
}

