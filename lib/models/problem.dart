import 'dart:convert';

class BlankInput {
  final int index;
  final String placeholder;
  final String ansHash;
  final int size;
  final List<String> options;

  BlankInput({
    required this.index,
    required this.placeholder,
    required this.ansHash,
    required this.size,
    this.options = const [],
  });

  factory BlankInput.fromJson(Map<String, dynamic> json) {
    return BlankInput(
      index: json['index'] as int,
      placeholder: json['placeholder']?.toString() ?? '',
      ansHash: json['ans_hash']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 2,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'placeholder': placeholder,
        'ans_hash': ansHash,
        'size': size,
        'options': options,
      };
}

class QuestionItem {
  final String text;
  final String placeholder;
  final int? blankIndex;
  final List<String> options;

  QuestionItem({
    required this.text,
    required this.placeholder,
    this.blankIndex,
    this.options = const [],
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    return QuestionItem(
      text: json['text']?.toString() ?? '',
      placeholder: json['placeholder']?.toString() ?? '',
      blankIndex: json['blank_index'] != null ? (json['blank_index'] as num).toInt() : null,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'placeholder': placeholder,
        'blank_index': blankIndex,
        'options': options,
      };
}

class Problem {
  final int id;
  final String statement;
  final String name;
  final String knowledgePoint;
  final List<String> images;
  final String codeTemplate;
  final List<QuestionItem> questions;
  final List<BlankInput> inputs;
  final int totalInputs;

  Problem({
    required this.id,
    required this.statement,
    required this.name,
    required this.knowledgePoint,
    required this.images,
    required this.codeTemplate,
    required this.questions,
    required this.inputs,
    required this.totalInputs,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] as int,
      statement: json['statement']?.toString() ?? json['id'].toString(),
      name: json['name']?.toString() ?? 'Problem ${json['id']}',
      knowledgePoint: json['knowledge_point']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      codeTemplate: json['code_template']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inputs: (json['inputs'] as List<dynamic>?)
              ?.map((e) => BlankInput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalInputs: (json['total_inputs'] as num?)?.toInt() ??
          ((json['inputs'] as List<dynamic>?)?.length ?? 0),
    );
  }

  static List<Problem> listFromJson(String jsonString) {
    final List<dynamic> parsed = jsonDecode(jsonString) as List<dynamic>;
    return parsed.map((e) => Problem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
