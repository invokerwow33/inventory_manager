import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DocumentTemplateType {
  handover('Акт приема-передачи', Icons.assignment_turned_in, Colors.blue),
  returnDoc('Акт возврата', Icons.assignment_return, Colors.green),
  writeoff('Акт списания', Icons.delete_forever, Colors.red),
  transfer('Накладная на перемещение', Icons.swap_horiz, Colors.orange),
  receipt('Приходный ордер', Icons.add_box, Colors.purple),
  maintenance('Акт технического обслуживания', Icons.build, Colors.teal),
  inventory('Инвентаризационная опись', Icons.fact_check, Colors.indigo),
  custom('Пользовательский', Icons.description, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const DocumentTemplateType(this.label, this.icon, this.color);

  static DocumentTemplateType fromString(String value) {
    return DocumentTemplateType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DocumentTemplateType.custom,
    );
  }
}

class DocumentTemplate {
  String id;
  String name;
  DocumentTemplateType type;
  String content;
  List<String>? variables;
  String? headerImage;
  String? footerText;
  bool isDefault;
  bool isActive;
  String? createdBy;
  DateTime createdAt;
  DateTime updatedAt;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    this.variables,
    this.headerImage,
    this.footerText,
    this.isDefault = false,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'content': content,
      'variables': variables?.join(','),
      'header_image': headerImage,
      'footer_text': footerText,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DocumentTemplate.fromMap(Map<String, dynamic> map) {
    return DocumentTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      type: DocumentTemplateType.fromString(map['type'] ?? 'custom'),
      content: map['content'] ?? '',
      variables: map['variables']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      headerImage: map['header_image'],
      footerText: map['footer_text'],
      isDefault: map['is_default'] == 1 || map['is_default'] == true,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdBy: map['created_by'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String generateDocument(Map<String, String> variableValues) {
    String result = content;
    variableValues.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  List<String> extractVariables() {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }
}

class DocumentSignature {
  String id;
  String documentId;
  String documentType;
  String signerId;
  String signerName;
  String signerRole;
  List<int> signatureData;
  DateTime signedAt;
  String? ipAddress;
  String? userAgent;
  String? notes;

  DocumentSignature({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.signerId,
    required this.signerName,
    required this.signerRole,
    required this.signatureData,
    required this.signedAt,
    this.ipAddress,
    this.userAgent,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'document_type': documentType,
      'signer_id': signerId,
      'signer_name': signerName,
      'signer_role': signerRole,
      'signature_data': signatureData.join(','),
      'signed_at': signedAt.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'notes': notes,
    };
  }

  factory DocumentSignature.fromMap(Map<String, dynamic> map) {
    return DocumentSignature(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      documentType: map['document_type'] ?? '',
      signerId: map['signer_id']?.toString() ?? '',
      signerName: map['signer_name'] ?? '',
      signerRole: map['signer_role'] ?? '',
      signatureData: map['signature_data']?.toString().split(',').map((s) => int.tryParse(s) ?? 0).toList() ?? [],
      signedAt: DateTime.tryParse(map['signed_at'] ?? '') ?? DateTime.now(),
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      notes: map['notes'],
    );
  }

  String get formattedSignedAt {
    return DateFormat('dd.MM.yyyy HH:mm:ss').format(signedAt);
  }
}

class GeneratedDocument {
  String id;
  String templateId;
  String templateName;
  String title;
  String content;
  String? entityType;
  String? entityId;
  List<DocumentSignature>? signatures;
  String? pdfPath;
  String status;
  String? createdBy;
  DateTime createdAt;
  DateTime updatedAt;

  GeneratedDocument({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.title,
    required this.content,
    this.entityType,
    this.entityId,
    this.signatures,
    this.pdfPath,
    this.status = 'draft',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'template_name': templateName,
      'title': title,
      'content': content,
      'entity_type': entityType,
      'entity_id': entityId,
      'pdf_path': pdfPath,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GeneratedDocument.fromMap(Map<String, dynamic> map) {
    return GeneratedDocument(
      id: map['id']?.toString() ?? '',
      templateId: map['template_id']?.toString() ?? '',
      templateName: map['template_name'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      entityType: map['entity_type'],
      entityId: map['entity_id']?.toString(),
      pdfPath: map['pdf_path'],
      status: map['status'] ?? 'draft',
      createdBy: map['created_by'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isSigned => signatures != null && signatures!.isNotEmpty;
  bool get isDraft => status == 'draft';
  bool get isFinalized => status == 'finalized';

  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }
}
