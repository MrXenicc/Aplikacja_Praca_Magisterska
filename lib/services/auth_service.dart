// lib/services/auth_service.dart
import '../repositories/user_repository.dart';
import '../models/user.dart';

class AuthService {
  final UserRepository _userRepo = UserRepository();

  Future<bool> register(String username, String password) async {
    return await _userRepo.createUser(username, password);
  }

  Future<User?> login(String username, String password) async {
    return await _userRepo.authenticate(username, password);
  }

}
