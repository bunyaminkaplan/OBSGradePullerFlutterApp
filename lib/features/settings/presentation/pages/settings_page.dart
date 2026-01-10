import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_view_model.dart';

/// Settings Page - Presentation Layer
/// Uygulama ayarları ekranı
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ayarlar",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Auto Login Section
              _buildSectionHeader(context, "Otomatik Giriş"),
              const SizedBox(height: 8),
              _buildMicrocopyText(
                context,
                "Uygulama açıldığında seçili hesaba otomatik giriş yapılır.",
              ),
              const SizedBox(height: 16),
              _buildAutoLoginCard(context, viewModel, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Icon(Icons.rocket_launch, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildMicrocopyText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
      ),
    );
  }

  Widget _buildAutoLoginCard(
    BuildContext context,
    SettingsViewModel viewModel,
    bool isDark,
  ) {
    final profiles = viewModel.profiles;
    final selectedProfile = viewModel.quickLoginProfile;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Kapalı seçeneği
          _buildRadioTile(
            context: context,
            title: "Kapalı",
            subtitle: "Her açılışta hesap seçimi yapılır",
            isSelected: selectedProfile == null,
            onTap: () => viewModel.setQuickLogin(null),
            isDark: isDark,
          ),
          if (profiles.isNotEmpty)
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          // Profil seçenekleri
          ...profiles.asMap().entries.map((entry) {
            final index = entry.key;
            final profile = entry.value;
            final username = profile['username'] ?? '';
            final alias = profile['alias'] ?? 'Varsayılan';
            final isLast = index == profiles.length - 1;

            return Column(
              children: [
                _buildRadioTile(
                  context: context,
                  title: alias,
                  subtitle: username,
                  isSelected: selectedProfile == username,
                  onTap: () => viewModel.setQuickLogin(username),
                  isDark: isDark,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Check icon for selected
              if (isSelected)
                const Icon(Icons.check, color: Colors.blueAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
