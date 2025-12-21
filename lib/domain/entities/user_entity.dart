class UserEntity {
  final String studentNumber;
  final String
  password; // In a real app, this might be a token, but for now we keep credentials as per legacy logic
  final String? alias;

  UserEntity({required this.studentNumber, required this.password, this.alias});
}
