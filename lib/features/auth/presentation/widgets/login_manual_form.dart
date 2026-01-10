import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_view_model.dart';
import '../../../../infrastructure/storage/secure_storage_service.dart';
import '../../../../core/presentation/widgets/shimmer_box.dart';
import '../../../grades/presentation/pages/grades_page.dart';

class LoginManualForm extends StatefulWidget {
  final VoidCallback onCancel; // To go back to profiles
  final bool showCancelButton; // Only show if profiles exist
  final String? initialUsername;
  final String? initialPassword;

  const LoginManualForm({
    super.key,
    required this.onCancel,
    this.showCancelButton = false,
    this.initialUsername,
    this.initialPassword,
  });

  @override
  State<LoginManualForm> createState() => _LoginManualFormState();
}

class _LoginManualFormState extends State<LoginManualForm> {
  late final TextEditingController _userController;
  late final TextEditingController _passController;
  final _captchaController = TextEditingController();
  final _aliasController = TextEditingController();
  late final SecureStorageService storage;

  @override
  void initState() {
    super.initState();
    storage = context.read<SecureStorageService>();
    _userController = TextEditingController(text: widget.initialUsername);
    _passController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void didUpdateWidget(covariant LoginManualForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUsername != oldWidget.initialUsername &&
        widget.initialUsername != null) {
      _userController.text = widget.initialUsername!;
    }
    if (widget.initialPassword != oldWidget.initialPassword &&
        widget.initialPassword != null) {
      _passController.text = widget.initialPassword!;
    }
  }

  bool _rememberMe = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _captchaController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final viewModel = context.read<LoginViewModel>();

    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final manualCaptcha = _captchaController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bilgileri girin"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Attempt Login via ViewModel
    final success = await viewModel.login(
      username,
      password,
      manualCaptcha: manualCaptcha.isNotEmpty ? manualCaptcha : null,
    );

    if (success && mounted) {
      if (_rememberMe) {
        String alias = _aliasController.text.trim();
        if (alias.isEmpty) alias = username;
        await storage.saveProfile(
          username: username,
          password: password,
          alias: alias,
        );
      }

      // Navigate to GradesScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GradesPage()),
      );
    } else if (!success && mounted) {
      _captchaController.clear();
      // Error is handled by SnackBar in view model consumer or logic above
      // But we show it here just in case if not handled elsewhere
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final isLoading =
        viewModel.state == LoginState.loadingCaptcha ||
        viewModel.state == LoginState.loggingIn;

    // Auto-fill Captcha Logic
    if (viewModel.captchaCode.isNotEmpty &&
        _captchaController.text.isEmpty &&
        !isLoading) {
      _captchaController.text = viewModel.captchaCode;
    }

    return Column(
      children: [
        _textField(_userController, "Öğrenci No", Icons.person_outline),
        const SizedBox(height: 16),
        _textField(_passController, "Şifre", Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              height: 56,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: viewModel.captchaImage != null
                      ? Image.memory(
                          viewModel.captchaImage!,
                          width: 120,
                          height: 56,
                          fit: BoxFit.fill,
                          key: ValueKey(viewModel.captchaImage.hashCode),
                        )
                      : const ShimmerBox(
                          width: 120,
                          height: 56,
                          borderRadius: BorderRadius.zero,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                _captchaController,
                "Kod",
                Icons.vpn_key_outlined,
                suffix: IconButton(
                  onPressed: () {
                    _captchaController.clear();
                    viewModel.loadCaptcha();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              const Text("Beni Hatırla"),
            ],
          ),
        ),

        // AnimatedSize causes overflow, use AnimatedCrossFade instead
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _rememberMe
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _textField(
              _aliasController,
              "Hesap İsmi",
              Icons.label_outline,
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _handleLogin(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Giriş Yap",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // Error is now shown via SnackBar in _handleLogin()
        if (widget.showCancelButton)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text(
                "Kayıtlı Hesapla",
                style: TextStyle(fontSize: 16),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String lbl,
    IconData icn, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: lbl,
        prefixIcon: Icon(icn),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
      ),
    );
  }
}
