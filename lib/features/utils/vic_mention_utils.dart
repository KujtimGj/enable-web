import '../entities/vicModel.dart';
import '../providers/vicProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class VICMentionUtils {
  /// Extracts VIC mentions from text and returns enhanced query with preferences
  static Future<Map<String, dynamic>> extractVICMentionsAndPreferences(
    String query,
    BuildContext context,
  ) async {
    final vicProvider = Provider.of<VICProvider>(context, listen: false);
    final vics = vicProvider.vics;
    
    // Find all @VIC mentions in the query
    final RegExp mentionRegex = RegExp(r'@([^\s]+)');
    final matches = mentionRegex.allMatches(query);
    
    List<String> mentionedVicNames = [];
    List<String> extractedPreferences = [];
    Map<String, String> vicNameToPreferences = {};
    
    for (Match match in matches) {
      final mentionedName = match.group(1);
      if (mentionedName != null) {
        mentionedVicNames.add(mentionedName);
        
        // Find the VIC by name
        final vic = vics.firstWhere(
          (v) => (v.fullName ?? '').toLowerCase().contains(mentionedName.toLowerCase()),
          orElse: () => VICModel(), // Return empty VIC if not found
        );
        
        if (vic.fullName != null) {
          // Extract preferences from the VIC
          final preferences = _extractPreferencesFromVIC(vic);
          if (preferences.isNotEmpty) {
            extractedPreferences.addAll(preferences);
            vicNameToPreferences[mentionedName] = preferences.join(', ');
          }
        }
      }
    }
    
    // Create enhanced query
    String enhancedQuery = query;
    if (extractedPreferences.isNotEmpty) {
      final preferencesText = extractedPreferences.join(', ');
      enhancedQuery = '$query\n\nVIC Preferences: $preferencesText';
      print('VICMentionUtils: Enhanced query with preferences: $enhancedQuery');
    } else {
      print('VICMentionUtils: No preferences found, using original query');
    }
    
    return {
      'originalQuery': query,
      'enhancedQuery': enhancedQuery,
      'mentionedVics': mentionedVicNames,
      'extractedPreferences': extractedPreferences,
      'vicPreferences': vicNameToPreferences,
    };
  }
  
  /// Extracts preferences from a VIC model
  static List<String> _extractPreferencesFromVIC(VICModel vic) {
    List<String> preferences = [];
    
    print('VICMentionUtils: Extracting preferences for VIC: ${vic.fullName}');
    
    // Extract from preferences field (if it's a Map)
    if (vic.preferences != null) {
      print('VICMentionUtils: VIC has preferences field: ${vic.preferences}');
      vic.preferences!.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          preferences.add(value.toString());
          print('VICMentionUtils: Added preference from field: $value');
        }
      });
    }
    
    // Extract from summary field (look for preference-related keywords)
    if (vic.summary != null && vic.summary!.isNotEmpty) {
      final summary = vic.summary!.toLowerCase();
      print('VICMentionUtils: VIC summary: ${vic.summary}');
      
      // Look for common preference keywords
      final preferenceKeywords = [
        'luxury', 'budget', 'family', 'business', 'quiet', 'loud', 'romantic',
        'adventure', 'relaxing', 'spa', 'beach', 'mountain', 'city', 'countryside',
        'fine dining', 'casual', 'vegetarian', 'vegan', 'gluten-free',
        'smoking', 'non-smoking', 'pet-friendly', 'accessible', 'hotel', 'restaurant'
      ];
      
      for (String keyword in preferenceKeywords) {
        if (summary.contains(keyword)) {
          preferences.add(keyword);
          print('VICMentionUtils: Added preference from summary: $keyword');
        }
      }
    }
    
    print('VICMentionUtils: Final preferences for ${vic.fullName}: $preferences');
    return preferences;
  }
  
  /// Gets VIC by name
  static VICModel? getVICByName(String name, List<VICModel> vics) {
    try {
      return vics.firstWhere(
        (vic) => (vic.fullName ?? '').toLowerCase().contains(name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Formats preferences for display
  static String formatPreferencesForDisplay(List<String> preferences) {
    if (preferences.isEmpty) return '';
    return preferences.join(', ');
  }
}
