import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String nombre;
  final String direccion;
  final String ciudad;
  final String telefono;

  const UserProfile({
    this.nombre = '',
    this.direccion = '',
    this.ciudad = '',
    this.telefono = '',
  });

  bool get isEmpty =>
      nombre.isEmpty && direccion.isEmpty && ciudad.isEmpty && telefono.isEmpty;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'direccion': direccion,
        'ciudad': ciudad,
        'telefono': telefono,
      };

  factory UserProfile.fromMap(Map<String, dynamic> data) => UserProfile(
        nombre: (data['nombre'] ?? '').toString(),
        direccion: (data['direccion'] ?? '').toString(),
        ciudad: (data['ciudad'] ?? '').toString(),
        telefono: (data['telefono'] ?? '').toString(),
      );
}

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference? get _profileRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('Usuarios').doc(uid).collection('datos').doc('perfil');
  }

  Future<UserProfile> getProfile() async {
    final ref = _profileRef;
    if (ref == null) return const UserProfile();
    try {
      final snap = await ref.get();
      if (!snap.exists) return const UserProfile();
      final data = snap.data() as Map<String, dynamic>?;
      return UserProfile.fromMap(data ?? {});
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final ref = _profileRef;
    if (ref == null) throw Exception('Usuario no autenticado');
    await ref.set(profile.toMap());
  }
}
