import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage
  /// [file] the file to upload
  /// [folder] the folder in storage to upload to (e.g. 'homework_attachments', 'submissions')
  /// [fileName] optional custom file name, if not provided a UUID will be generated
  Future<String> uploadFile(File file, String folder, {String? fileName}) async {
    try {
      // Generate a unique file name if not provided
      final String uniqueFileName = fileName ?? '${const Uuid().v4()}${_getFileExtension(file.path)}';
      final String filePath = '$folder/$uniqueFileName';

      // Upload file to Firebase Storage
      final Reference storageRef = _storage.ref().child(filePath);
      final UploadTask uploadTask = storageRef.putFile(file);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Deletes a file from Firebase Storage
  /// [fileUrl] the download URL of the file to delete
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract the file path from the URL
      final Uri uri = Uri.parse(fileUrl);
      final List<String> pathSegments = uri.pathSegments;
      final String filePath = pathSegments.skip(1).join('/'); // Skip 'gs' segment

      final Reference storageRef = _storage.ref().child(filePath);
      await storageRef.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Gets the file extension from a file path
  String _getFileExtension(String filePath) {
    final List<String> pathParts = filePath.split('.');
    if (pathParts.length > 1) {
      return '.${pathParts.last}';
    }
    return '';
  }

  /// Uploads an image file and returns the download URL
  Future<String> uploadImage(File imageFile, String folder) async {
    return await uploadFile(imageFile, folder);
  }

  /// Uploads a PDF or document file and returns the download URL
  Future<String> uploadDocument(File documentFile, String folder) async {
    return await uploadFile(documentFile, folder);
  }
}
