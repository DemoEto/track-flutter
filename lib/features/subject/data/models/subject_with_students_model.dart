// Enhanced Subject model that includes enrolled students
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

class SubjectWithStudentsModel {
  final SubjectModel subject;
  final List<UserModel> students;

  SubjectWithStudentsModel({required this.subject, required this.students});

  SubjectWithStudentsModel copyWith({SubjectModel? subject, List<UserModel>? students}) {
    return SubjectWithStudentsModel(subject: subject ?? this.subject, students: students ?? this.students);
  }
}
