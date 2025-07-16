// /home/ubuntu/lucasbeats_v4/project_android/lib/models/questionnaire_model.dart

// Placeholder QuestionnaireModel
class QuestionnaireModel {
  final String id;
  final String title;
  // Add other fields as needed based on usage

  QuestionnaireModel({
    required this.id,
    required this.title,
  });

  // Minimal factory constructor required by services
  factory QuestionnaireModel.fromJson(Map<String, dynamic> json) {
    return QuestionnaireModel(
      id: json["_id"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json["title"] ?? "Questionário Placeholder",
    );
  }

  // Added minimal toJson method as required by questionnaire_service.dart
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      // Add other fields if needed for serialization
    };
  }
}
