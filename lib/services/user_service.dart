import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    String? age,
    String? level,
    List<String>? interests,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'age': age,
      'level': level,
      'interests': interests ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAge({
    required String uid,
    required String age,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'age': age,
    }, SetOptions(merge: true));
  }

  Future<void> updateLevel({
    required String uid,
    required String level,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'level': level,
    }, SetOptions(merge: true));
  }

  Future<void> updateInterests({
    required String uid,
    required List<String> interests,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'interests': interests,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> addLearnedWord({
  required String uid,
  required String word,
  required String translation,
  required String example,
  required String exampleTranslation,
  required String topic,
}) async {
  await _firestore
      .collection('users')
      .doc(uid)
      .collection('learnedWords')
      .doc(word.toLowerCase())
      .set({
    'word': word,
    'translation': translation,
    'example': example,
    'exampleTranslation': exampleTranslation,
    'topic': topic,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

  Future<int> getLearnedWordsCount(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('learnedWords')
        .get();

    return snapshot.docs.length;
  }
  Future<void> saveExerciseProgress({
  required String uid,
  required String exerciseId,
  required int score,
  required int total,
  required bool completed,
}) async {
  await _firestore
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc(exerciseId)
      .set({
    'score': score,
    'total': total,
    'completed': completed,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<Map<String, dynamic>?> getExerciseProgress({
  required String uid,
  required String exerciseId,
}) async {
  final doc = await _firestore
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc(exerciseId)
      .get();

  return doc.data();
}

 Future<double> getOverallProgress(String uid) async {
  final learnedWordsSnapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('learnedWords')
      .get();

  final progressSnapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('progress')
      .get();

  final learnedWordsCount = learnedWordsSnapshot.docs.length;

  int completedExercises = 0;
  for (final doc in progressSnapshot.docs) {
    final data = doc.data();
    if (data['completed'] == true) {
      completedExercises++;
    }
  }

  // Простая формула общего прогресса:
  // 50% за изучение слов, 50% за выполненные упражнения
  final wordsProgress = (learnedWordsCount / 20).clamp(0, 1).toDouble();
  final exercisesProgress = (completedExercises / 5).clamp(0, 1).toDouble();

  return ((wordsProgress * 0.5) + (exercisesProgress * 0.5)).clamp(0, 1);
 }

  Future<List<Map<String, dynamic>>> getLearnedWords(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('learnedWords')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}