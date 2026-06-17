import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_utils.dart';
import 'core/session/session_manager.dart';

const String dniToken =
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImpmY2M5NTAxMjMwOUBnbWFpbC5jb20ifQ.UaK6eecpbt-mVnF9hI-BYSHtl6QQ5hCLU1MNItWe9P8';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _cargando = false;
  bool _consultandoDni = false;
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  String _mensajeAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      default:
        return 'No se pudo crear la cuenta. Intenta nuevamente.';
    }
  }

  Future<void> _consultarDni() async {
    final dni = _dniController.text.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El DNI debe tener 8 dígitos')),
      );
      return;
    }

    setState(() => _consultandoDni = true);

    try {
      final url = Uri.parse(
        'https://dniruc.apisperu.com/api/v1/dni/$dni?token=$dniToken',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Error al consultar DNI (${response.statusCode})');
      }

      final body = jsonDecode(response.body);
      Map<String, dynamic>? data;
      if (body is Map<String, dynamic>) {
        if (body['data'] is Map<String, dynamic>) {
          data = body['data'] as Map<String, dynamic>;
        } else if (body['success'] == true && body['data'] != null) {
          data = Map<String, dynamic>.from(body['data'] as Map);
        } else {
          data = body;
        }
      }

      if (data == null) {
        throw Exception('Respuesta de DNI no válida');
      }

      final nombres =
          (data['nombres'] ?? data['nombre'] ?? data['nombresCompletos'] ?? '')
              .toString();
      final apellidoPaterno =
          (data['apellidoPaterno'] ?? data['apellido_paterno'] ?? '')
              .toString();
      final apellidoMaterno =
          (data['apellidoMaterno'] ?? data['apellido_materno'] ?? '')
              .toString();

      if (nombres.isEmpty &&
          apellidoPaterno.isEmpty &&
          apellidoMaterno.isEmpty) {
        throw Exception('No se encontraron datos para ese DNI');
      }

      setState(() {
        _nombresController.text = nombres;
        _apellidoPaternoController.text = apellidoPaterno;
        _apellidoMaternoController.text = apellidoMaterno;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del DNI cargados correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al consultar DNI: $e')));
    } finally {
      if (mounted) setState(() => _consultandoDni = false);
    }
  }

  Future<void> _guardarPerfilUsuario({
    required String uid,
    required String dni,
    required String nombres,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String correo,
  }) async {
    await FirebaseFirestore.instance.collection('Usuarios').doc(uid).set({
      'dni': dni,
      'nombres': nombres,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'email': correo,
      'fechaRegistro': FieldValue.serverTimestamp(),
    });
  }

  String _mensajePerfilNoGuardado(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Cuenta creada. No se pudo guardar el perfil por permisos de Firestore.';
    }
    return 'Cuenta creada. No se pudo guardar el perfil, podrás completarlo luego.';
  }

  Future<String?> _intentarGuardarPerfilUsuario({
    required String uid,
    required String dni,
    required String nombres,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String correo,
  }) async {
    debugPrint('DEBUG REGISTER: saving Firestore profile');
    try {
      await _guardarPerfilUsuario(
        uid: uid,
        dni: dni,
        nombres: nombres,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        correo: correo,
      );
      return null;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('DEBUG REGISTER: profile save failed code=${e.code} error=$e');
      debugPrint('DEBUG REGISTER: profile save stack=$stackTrace');
      return _mensajePerfilNoGuardado(e);
    } catch (e, stackTrace) {
      debugPrint('DEBUG REGISTER: profile save failed code=unknown error=$e');
      debugPrint('DEBUG REGISTER: profile save stack=$stackTrace');
      return _mensajePerfilNoGuardado(e);
    }
  }

  Future<void> _finalizarRegistroExitoso(
    String uid, {
    String mensaje = 'Cuenta creada correctamente',
  }) async {
    if (!mounted) return;
    debugPrint('DEBUG SESSION: register success uid=$uid');
    debugPrint('DEBUG REGISTER: navigating to authenticated root');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
    SessionManager.resetNavigationToRoot();
  }

  Future<void> _crearCuenta() async {
    final dni = _dniController.text.trim();
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text;
    final nombres = _nombresController.text.trim();
    final apellidoPaterno = _apellidoPaternoController.text.trim();
    final apellidoMaterno = _apellidoMaternoController.text.trim();

    if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El DNI debe tener 8 dígitos')),
      );
      return;
    }

    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo electrónico')),
      );
      return;
    }

    if (contrasena.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      debugPrint('DEBUG REGISTER: creating auth user');
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: contrasena);

      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No se pudo crear el usuario');
      }
      debugPrint('DEBUG REGISTER: auth user created uid=${user.uid}');

      final perfilError = await _intentarGuardarPerfilUsuario(
        uid: user.uid,
        dni: dni,
        nombres: nombres,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        correo: correo,
      );

      await _finalizarRegistroExitoso(
        user.uid,
        mensaje: perfilError ?? 'Cuenta creada correctamente',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mensajeAuth(e))));
    } catch (e) {
      if (!mounted) return;
      if (debeIgnorarErrorAuth(e)) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          debugPrint('DEBUG REGISTER: auth user created uid=${user.uid}');
          final perfilError = await _intentarGuardarPerfilUsuario(
            uid: user.uid,
            dni: dni,
            nombres: nombres,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: apellidoMaterno,
            correo: correo,
          );
          await _finalizarRegistroExitoso(
            user.uid,
            mensaje: perfilError ?? 'Cuenta creada correctamente',
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo completar el registro. Intenta nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.memory, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'TECHNOVATE - Registro',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _consultandoDni ? null : _consultarDni,
              icon: _consultandoDni
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_consultandoDni ? 'Consultando...' : 'Consultar DNI'),
              style: ElevatedButton.styleFrom(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombresController,
              decoration: const InputDecoration(
                labelText: 'Nombres',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoPaternoController,
              decoration: const InputDecoration(
                labelText: 'Apellido paterno',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoMaternoController,
              decoration: const InputDecoration(
                labelText: 'Apellido materno',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contrasenaController,
              obscureText: _ocultarContrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarContrasena
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _ocultarContrasena = !_ocultarContrasena);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargando ? null : _crearCuenta,
              icon: _cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_cargando ? 'Creando cuenta...' : 'Crear cuenta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
