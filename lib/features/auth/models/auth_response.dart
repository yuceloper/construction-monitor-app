class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final List<String> permissions;
  final int? companyId;
  final String? companyName;
  final bool mustChangePassword;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.permissions = const [],
    this.companyId,
    this.companyName,
    this.mustChangePassword = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role']?.toString() ?? '',
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      companyId: (json['companyId'] as num?)?.toInt(),
      companyName: json['companyName']?.toString(),
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'userId': userId,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'permissions': permissions,
        'companyId': companyId,
        'companyName': companyName,
        'mustChangePassword': mustChangePassword,
      };

  AuthResponse copyWith({bool? mustChangePassword}) => AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        userId: userId,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        permissions: permissions,
        companyId: companyId,
        companyName: companyName,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  bool hasPermission(String permission) =>
      role == 'SYSADMIN' || permissions.contains(permission);

  bool get canViewProcess =>
      hasPermission('PROCESS_VIEW') || hasPermission('PROCESS_UPDATE');
  bool get canUpdateProcess => hasPermission('PROCESS_UPDATE');
  bool get canViewDailyTasks =>
      hasPermission('DAILY_TASK_VIEW') || hasPermission('DAILY_TASK_UPDATE');
  bool get canUpdateDailyTasks => hasPermission('DAILY_TASK_UPDATE');
  bool get canViewSafety => hasPermission('SAFETY_VIEW');
  bool get isBackOfficeAdmin => hasPermission('BACKOFFICE_ADMIN');

  String get fullName => '$firstName $lastName'.trim();
}
