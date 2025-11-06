  import 'package:firebase_auth/firebase_auth.dart';

  class FirebaseAuthDatasource {
    final _auth = FirebaseAuth.instance;

    Future<User?> signIn(String email, String password) async {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    }

    Future<User?> signUp(String email, String password) async {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    }

    Future<void> signOut() => _auth.signOut();

    User? get currentUser => _auth.currentUser;

    Stream<User?> authStateChanges() => _auth.authStateChanges();
  }
