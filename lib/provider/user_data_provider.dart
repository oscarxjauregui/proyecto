import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  String? _userName;
  String? _userEmail;
  String? _avatarUrl;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get avatarUrl => _avatarUrl;

  void setUserName(String? userName) {
    _userName = userName;
    notifyListeners(); // Notificar a los widgets que escuchan este proveedor sobre el cambio
  }

  void setUserEmail(String? userEmail) {
    _userEmail = userEmail;
    notifyListeners(); // Notificar a los widgets que escuchan este proveedor sobre el cambio
  }

  void setAvatarUrl(String? avatarUrl) {
    _avatarUrl = avatarUrl;
    notifyListeners(); // Notificar a los widgets que escuchan este proveedor sobre el cambio
  }
}
