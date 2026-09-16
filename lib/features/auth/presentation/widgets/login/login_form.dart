import 'package:epresensi_mobile/core/utils/device_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../bloc/login_bloc.dart';
import '../../bloc/login_event.dart';
import '../../bloc/login_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (!mounted) return;

    context.read<LoginBloc>().add(
      LoginRememberMeChanged(rememberMe),
    );

    if (rememberMe) {
      setState(() {
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      });
    }
  }

  Future<void> _saveUserCredentials(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString(
        'username',
        _usernameController.text,
      );
      await prefs.setString(
        'password',
        _passwordController.text,
      );
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('username');
      await prefs.remove('password');
    }
  }

  void _onLoginPressed(LoginState state) async {
    if (_formKey.currentState!.validate()) {
      await _saveUserCredentials(state.rememberMe);

      if (!mounted) return;

      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final deviceId = deviceInfo['kode_unik'] ?? '';

      if (!mounted) return;

      context.read<LoginBloc>().add(
        LoginSubmitted(
          username: _usernameController.text,
          password: _passwordController.text,
          deviceId: deviceId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Masukkan NIP',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.neutral500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.neutral200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.neutral200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary500,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
              hintStyle: const TextStyle(
                color: AppColors.neutral400,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'NIP tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          Text(
            'Password',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          BlocBuilder<LoginBloc, LoginState>(
            buildWhen: (previous, current) =>
                previous.isPasswordVisible != current.isPasswordVisible,
            builder: (context, state) {
              return TextFormField(
                controller: _passwordController,
                obscureText: !state.isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.neutral500,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.neutral500,
                    ),
                    onPressed: () {
                      context.read<LoginBloc>().add(
                        LoginPasswordVisibilityChanged(
                          !state.isPasswordVisible,
                        ),
                      );
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.neutral200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.neutral200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary500,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  hintStyle: const TextStyle(
                    color: AppColors.neutral400,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 3) {
                    return 'Password minimal 3 karakter';
                  }
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 12),

          BlocBuilder<LoginBloc, LoginState>(
            buildWhen: (previous, current) =>
                previous.rememberMe != current.rememberMe,
            builder: (context, state) {
              return Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: state.rememberMe,
                      onChanged: (value) {
                        context.read<LoginBloc>().add(
                          LoginRememberMeChanged(value ?? false),
                        );
                      },
                      activeColor: AppColors.primary500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ingat Saya',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.status == LoginStatus.loading
                      ? null
                      : () => _onLoginPressed(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primary300,
                    disabledForegroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: state.status == LoginStatus.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}