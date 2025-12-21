import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/login_view_model.dart';
import '../../../services/storage_service.dart';

class LoginManualForm extends StatefulWidget {
  final VoidCallback onCancel; // To go back to profiles
  final bool showCancelButton; // Only show if profiles exist

  const LoginManualForm({
    super.key,
    required this.onCancel,
    this.showCancelButton = false,
  });

  @override
  State<LoginManualForm> createState() => _LoginManualFormState();
}

class _LoginManualFormState extends State<LoginManualForm> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _captchaController = TextEditingController();
  final _aliasController = TextEditingController();
  final _storage = StorageService();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri girin")));
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
        await _storage.saveProfile(username, password, alias);
      }
      // Navigation is handled by the parent listener or here?
      // Ideally parent listener handles navigation to keep this widget dumb about routing.
    } else if (!success && mounted) {
      _captchaController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final isLoading = viewModel.state == LoginState.loading;
    final error = viewModel.errorMessage;

    // Auto-fill Captcha Logic
    if (viewModel.captchaCode.isNotEmpty &&
        _captchaController.text.isEmpty &&
        !isLoading) {
      // Only set if field is empty to allow manual override
      // _captchaController.text = viewModel.captchaCode;
      // Better: Just show hint text or let user tap to fill
    }

    return Column(
      children: [
        if (isLoading) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(error.isNotEmpty ? error : "İşleniyor..."),
        ] else ...[
          _textField(_userController, "Öğrenci No", Icons.person_outline),
          const SizedBox(height: 16),
          _textField(
            _passController,
            "Şifre",
            Icons.lock_outline,
            obscure: true,
          ),
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
                  child: viewModel.captchaImage != null
                      ? Image.memory(viewModel.captchaImage!, fit: BoxFit.fill)
                      : Container(color: Colors.grey[200]),
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

          if (viewModel.captchaCode.isNotEmpty && !isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () => _captchaController.text = viewModel.captchaCode,
                child: Text(
                  "AI Tahmini: ${viewModel.captchaCode} (Dokun)",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              const Text("Beni Hatırla"),
            ],
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _rememberMe
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _textField(
                      _aliasController,
                      "Hesap İsmi",
                      Icons.label_outline,
                    ),
                  )
                : const SizedBox.shrink(),
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

          if (error.isNotEmpty && !isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error, style: TextStyle(color: Colors.red[600])),
            ),

          if (widget.showCancelButton)
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Kayıtlı Hesapla"),
            ),
        ],
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
