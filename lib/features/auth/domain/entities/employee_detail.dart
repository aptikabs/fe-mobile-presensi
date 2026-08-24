import 'package:equatable/equatable.dart';

class EmployeeDetail extends Equatable {
  final String id;
  final String nip;
  final String nama;
  final String email;
  final String jenisKelamin;
  final String jabatanNama;
  final String unorNama;
  final String unorIndukNama;
  final String unorId;

  const EmployeeDetail({
    required this.id,
    required this.nip,
    required this.nama,
    required this.email,
    required this.jenisKelamin,
    required this.jabatanNama,
    required this.unorNama,
    required this.unorIndukNama,
    required this.unorId,
  });

  @override
  List<Object?> get props => [
    id,
    nip,
    nama,
    email,
    jenisKelamin,
    jabatanNama,
    unorNama,
    unorIndukNama,
    unorId,
  ];
}
