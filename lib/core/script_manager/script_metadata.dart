class ScriptMetadata {
  final String id;
  final String version;
  final String checksum; // SHA-256
  final String? signature; // RSA Signature (Optional)
  final String localPath;

  const ScriptMetadata({
    required this.id,
    required this.version,
    required this.checksum,
    required this.localPath,
    this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'checksum': checksum,
      'signature': signature,
      'localPath': localPath,
    };
  }

  factory ScriptMetadata.fromJson(Map<String, dynamic> json) {
    return ScriptMetadata(
      id: json['id'] as String,
      version: json['version'] as String,
      checksum: json['checksum'] as String,
      localPath: json['localPath'] as String,
      signature: json['signature'] as String?,
    );
  }
}
