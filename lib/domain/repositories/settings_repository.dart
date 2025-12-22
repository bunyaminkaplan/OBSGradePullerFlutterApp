abstract class ISettingsRepository {
  Future<String> toggleUniversity();
  Future<String?> getUniversityUrl();
  Future<void> saveUniversityUrl(String url);
}
