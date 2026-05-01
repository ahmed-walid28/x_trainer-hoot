import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FitnessMemory {
  // User Profile Data
  String? name;
  double? weightKg;
  double? heightCm;
  int? age;
  String? gender; // 'male' | 'female'
  String? goal; // 'bulking' | 'cutting' | 'maintenance'
  String? activityLevel; // 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'
  List<String> dietaryPreferences = [];
  List<String> allergies = [];
  List<String> medicalConditions = [];
  
  // Calculated values
  double? calculatedBmr;
  double? calculatedTdee;
  double? calculatedTargetKcal;
  
  // Session tracking
  DateTime? lastUpdated;
  List<Map<String, dynamic>> conversationHistory = [];
  
  // Computed properties
  double? get bmi {
    if (weightKg != null && heightCm != null && heightCm! > 0) {
      return weightKg! / ((heightCm! / 100) * (heightCm! / 100));
    }
    return null;
  }
  
  bool get isProfileComplete {
    return weightKg != null && 
           heightCm != null && 
           age != null && 
           gender != null && 
           goal != null;
  }
  
  // Constructor
  FitnessMemory();
  
  // From JSON
  factory FitnessMemory.fromJson(Map<String, dynamic> json) {
    final memory = FitnessMemory();
    memory.name = json['name'];
    memory.weightKg = json['weight_kg']?.toDouble();
    memory.heightCm = json['height_cm']?.toDouble();
    memory.age = json['age'];
    memory.gender = json['gender'];
    memory.goal = json['goal'];
    memory.activityLevel = json['activity_level'];
    memory.dietaryPreferences = List<String>.from(json['dietary_preferences'] ?? []);
    memory.allergies = List<String>.from(json['allergies'] ?? []);
    memory.medicalConditions = List<String>.from(json['medical_conditions'] ?? []);
    memory.calculatedBmr = json['calculated_bmr']?.toDouble();
    memory.calculatedTdee = json['calculated_tdee']?.toDouble();
    memory.calculatedTargetKcal = json['calculated_target_kcal']?.toDouble();
    memory.lastUpdated = json['last_updated'] != null 
        ? DateTime.parse(json['last_updated']) 
        : null;
    memory.conversationHistory = List<Map<String, dynamic>>.from(json['conversation_history'] ?? []);
    return memory;
  }
  
  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age': age,
      'gender': gender,
      'goal': goal,
      'activity_level': activityLevel,
      'dietary_preferences': dietaryPreferences,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'calculated_bmr': calculatedBmr,
      'calculated_tdee': calculatedTdee,
      'calculated_target_kcal': calculatedTargetKcal,
      'last_updated': lastUpdated?.toIso8601String(),
      'conversation_history': conversationHistory,
    };
  }
  
  // Load from file
  static Future<FitnessMemory> load() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fitness_memory.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString);
        return FitnessMemory.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading fitness memory: $e');
    }
    return FitnessMemory();
  }
  
  // Save to file
  Future<void> save() async {
    try {
      lastUpdated = DateTime.now();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fitness_memory.json');
      final jsonString = jsonEncode(toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving fitness memory: $e');
    }
  }
  
  // Calculate BMR using Mifflin-St Jeor
  double? calculateBmr() {
    if (weightKg == null || heightCm == null || age == null || gender == null) {
      return null;
    }
    
    if (gender?.toLowerCase() == 'female') {
      calculatedBmr = (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) - 161;
    } else {
      calculatedBmr = (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) + 5;
    }
    
    return calculatedBmr;
  }
  
  // Calculate TDEE
  double? calculateTdee() {
    final bmr = calculateBmr();
    if (bmr == null || activityLevel == null) return null;
    
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    
    calculatedTdee = bmr * (multipliers[activityLevel] ?? 1.2);
    return calculatedTdee;
  }
  
  // Calculate target calories based on goal
  double? calculateTargetKcal() {
    final tdee = calculateTdee();
    if (tdee == null || goal == null) return null;
    
    switch (goal?.toLowerCase()) {
      case 'bulking':
        calculatedTargetKcal = tdee + 400;
        break;
      case 'cutting':
        calculatedTargetKcal = tdee - 500;
        break;
      case 'maintenance':
      default:
        calculatedTargetKcal = tdee;
    }
    
    return calculatedTargetKcal;
  }
  
  // Get macro split based on goal
  Map<String, dynamic>? getMacroSplit() {
    if (weightKg == null || calculatedTargetKcal == null || goal == null) {
      return null;
    }
    
    double proteinPerKg;
    double fatPercent;
    
    switch (goal?.toLowerCase()) {
      case 'bulking':
        proteinPerKg = 2.0;
        fatPercent = 0.28;
        break;
      case 'cutting':
        proteinPerKg = 2.2;
        fatPercent = 0.23;
        break;
      case 'maintenance':
      default:
        proteinPerKg = 1.8;
        fatPercent = 0.28;
    }
    
    final proteinG = weightKg! * proteinPerKg;
    final fatKcal = calculatedTargetKcal! * fatPercent;
    final fatG = fatKcal / 9;
    final proteinKcal = proteinG * 4;
    final fatKcalFinal = fatG * 9;
    final carbsKcal = calculatedTargetKcal! - proteinKcal - fatKcalFinal;
    final carbsG = carbsKcal / 4;
    
    return {
      'protein_g': proteinG.round(),
      'protein_percent': ((proteinKcal / calculatedTargetKcal!) * 100).round(),
      'carbs_g': carbsG.round(),
      'carbs_percent': ((carbsKcal / calculatedTargetKcal!) * 100).round(),
      'fat_g': fatG.round(),
      'fat_percent': ((fatKcalFinal / calculatedTargetKcal!) * 100).round(),
    };
  }
  
  // Auto-detect goal from keywords
  static String? detectGoal(String text) {
    final lowerText = text.toLowerCase();
    
    final bulkingKeywords = ['bulk', 'gain', 'muscle', 'تحجيم', 'تضخيم', 'أكبر', 'تكبير'];
    final cuttingKeywords = ['cut', 'lean', 'fat loss', 'lose', 'تقطيع', 'حرق', 'تخسيس', 'خسارة', 'نزل وزن', 'رشاقة', 'نحيف'];
    final maintenanceKeywords = ['maintain', 'صيانة', 'ثبات', 'نفس الوزن'];
    
    for (final keyword in bulkingKeywords) {
      if (lowerText.contains(keyword)) return 'bulking';
    }
    for (final keyword in cuttingKeywords) {
      if (lowerText.contains(keyword)) return 'cutting';
    }
    for (final keyword in maintenanceKeywords) {
      if (lowerText.contains(keyword)) return 'maintenance';
    }
    
    return null;
  }
  
  // Update profile from user message
  void updateFromMessage(String text) {
    final lowerText = text.toLowerCase();
    
    // Weight detection
    final weightRegex = RegExp(r'(وزني|وزن|weight|w)[\s:]*(\d+(?:\.\d+)?)[\s]*(ك|kg|كيلو|kilos)?', caseSensitive: false);
    final weightMatch = weightRegex.firstMatch(text);
    if (weightMatch != null) {
      weightKg = double.tryParse(weightMatch.group(2)!);
    }
    
    // Height detection
    final heightRegex = RegExp(r'(طولي|طول|height|h)[\s:]*(\d+(?:\.\d+)?)[\s]*(سم|cm|م|m)?', caseSensitive: false);
    final heightMatch = heightRegex.firstMatch(text);
    if (heightMatch != null) {
      heightCm = double.tryParse(heightMatch.group(2)!);
    }
    
    // Age detection
    final ageRegex = RegExp(r'(عمري|عمر|age|عندي)[\s:]*(\d+)[\s]*(سنة|years|year)?', caseSensitive: false);
    final ageMatch = ageRegex.firstMatch(text);
    if (ageMatch != null) {
      age = int.tryParse(ageMatch.group(2)!);
    }
    
    // Gender detection
    if (lowerText.contains('male') || lowerText.contains('ذكر') || lowerText.contains('راجل')) {
      gender = 'male';
    } else if (lowerText.contains('female') || lowerText.contains('أنثى') || lowerText.contains('بنت') || lowerText.contains('ست')) {
      gender = 'female';
    }
    
    // Goal detection
    final detectedGoal = detectGoal(text);
    if (detectedGoal != null) {
      goal = detectedGoal;
    }
    
    // Activity level detection
    if (lowerText.contains('sedentary') || lowerText.contains('مقعد') || lowerText.contains('ما بتتحركش')) {
      activityLevel = 'sedentary';
    } else if (lowerText.contains('light') || lowerText.contains('خفيف') || lowerText.contains('1-3')) {
      activityLevel = 'light';
    } else if (lowerText.contains('moderate') || lowerText.contains('متوسط') || lowerText.contains('3-5')) {
      activityLevel = 'moderate';
    } else if (lowerText.contains('active') || lowerText.contains('نشط') || lowerText.contains('6-7')) {
      activityLevel = 'active';
    } else if (lowerText.contains('very active') || lowerText.contains('رياضي') || lowerText.contains('athlete')) {
      activityLevel = 'very_active';
    }
    
    // Recalculate if we have all data
    if (weightKg != null && heightCm != null && age != null && gender != null && goal != null) {
      calculateTargetKcal();
    }
  }
}
