import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalificacionesScreen extends StatefulWidget {
  final String myUserId;

  const CalificacionesScreen({required this.myUserId, Key? key})
      : super(key: key);

  @override
  State<CalificacionesScreen> createState() => _CalificacionesScreenState();
}

class _CalificacionesScreenState extends State<CalificacionesScreen> {
  List<Map<String, dynamic>> calificaciones = [];

  @override
  void initState() {
    super.initState();
    obtenerCalificaciones();
  }

  Future<void> obtenerCalificaciones() async {
    final calificacionesQuery = await FirebaseFirestore.instance
        .collection('clase-calificacion')
        .where('userId', isEqualTo: widget.myUserId)
        .get();

    if (calificacionesQuery.docs.isNotEmpty) {
      final List<Map<String, dynamic>> tempList = [];
      for (final doc in calificacionesQuery.docs) {
        final calificacionesData = doc.data();
        final classId = calificacionesData['classId'];
        final classDoc = await FirebaseFirestore.instance
            .collection('class')
            .doc(classId)
            .get();

        tempList.add({
          'className': classDoc['nombre'],
          'parcial1': calificacionesData['parcial1']?.toDouble() ?? 'N/A',
          'parcial2': calificacionesData['parcial2']?.toDouble() ?? 'N/A',
          'parcial3': calificacionesData['parcial3']?.toDouble() ?? 'N/A',
          'parcial4': calificacionesData['parcial4']?.toDouble() ?? 'N/A',
        });
      }
      setState(() {
        calificaciones = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones'),
      ),
      body: calificaciones.isNotEmpty
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Clase')),
                  DataColumn(label: Text('Parcial 1')),
                  DataColumn(label: Text('Parcial 2')),
                  DataColumn(label: Text('Parcial 3')),
                  DataColumn(label: Text('Parcial 4')),
                ],
                rows: calificaciones
                    .map(
                      (calificacion) => DataRow(
                        cells: [
                          DataCell(Text(calificacion['className'])),
                          DataCell(Text('${calificacion['parcial1']}')),
                          DataCell(Text('${calificacion['parcial2']}')),
                          DataCell(Text('${calificacion['parcial3']}')),
                          DataCell(Text('${calificacion['parcial4']}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            )
          : const Center(
              child: Text('No hay calificaciones'),
            ),
    );
  }
}
