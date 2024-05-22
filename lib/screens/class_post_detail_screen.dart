import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassPostDetailScreen extends StatelessWidget {
  final String classId;
  final String userId;

  const ClassPostDetailScreen({
    required this.classId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de la Tarea'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('class-tarea')
            .where('classId', isEqualTo: classId)
            .where('userId', isEqualTo: userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las tareas'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay tareas enviadas'));
          } else {
            final tasks = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final taskData = tasks[index].data() as Map<String, dynamic>;
                final fecha = taskData['timestamp'].toDate();
                final formattedDate =
                    DateFormat('dd MMM yyyy, HH:mm').format(fecha);
                final imageUrl = taskData['imageUrl'];
                final pdfUrl = taskData['pdfUrl'];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha de entrega: $formattedDate',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        if (pdfUrl != null && pdfUrl.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerScreen(
                                    pdfUrl: pdfUrl,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Ver PDF',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        SizedBox(height: 10),
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Image.network(imageUrl),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;

  const PDFViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFDocument? _pdfDocument;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final pdfDocument = await PDFDocument.fromURL(widget.pdfUrl);
      setState(() {
        _pdfDocument = pdfDocument;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar el PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pdfDocument != null
              ? PDFViewer(
                  document: _pdfDocument!,
                  indicatorBackground: Colors.red,
                  // Puedes personalizar las propiedades del visor de PDF aquí
                )
              : Center(child: Text('No se pudo cargar el PDF')),
    );
  }
}
