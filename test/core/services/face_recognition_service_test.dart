import 'package:epresensi_mobile/core/services/face_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = FaceRecognitionService();

  test('cosine similarity is one for identical vectors', () {
    expect(service.cosineSimilarity([1, 0, 0], [1, 0, 0]), closeTo(1, 1e-9));
  });

  test('cosine similarity is zero for orthogonal vectors', () {
    expect(service.cosineSimilarity([1, 0], [0, 1]), closeTo(0, 1e-9));
  });

  test('cosine similarity rejects different dimensions', () {
    expect(service.cosineSimilarity([1, 0], [1]), 0);
  });
}
