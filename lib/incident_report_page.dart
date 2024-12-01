import 'package:avaguard/audio_recorder.dart';
import 'package:avaguard/resources/firestore_methods.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'send_loose_record.dart';

class IncidentReportPage extends StatefulWidget {
  final userId;

  const IncidentReportPage({super.key, required this.userId});

  @override
  _IncidentReportPageState createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage>
    with TickerProviderStateMixin {
  final _recorder = AudioRecord();
  String selectedDate = "Informe a data e hora";
  final List<PlatformFile> _selectedFiles = [];
  bool isSending = false;
  bool isSuccess = false;
  late AnimationController _successController;
  SharedPreferences? prefs;
  final TextEditingController _descriptionController = TextEditingController();
  final SendLooseRecord _sendLooseRecord = SendLooseRecord();
  final List<String> urls = [];

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  void initState() {
    super.initState();

    initPrefs();

    // Inicializa o AnimationController sem duração padrão
    _successController = AnimationController(vsync: this);
    _successController.addListener(() {
      if (_successController.isCompleted) {
        setState(() {
          isSuccess = false; // Oculta a animação de sucesso
        });
      }
    });
  }

  @override
  void dispose() {
    _successController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Método para selecionar data
  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    print(
        "Gravação pendente: ${prefs!.getString('recordingId')} - ${prefs!.getString('filePath')}");
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate.toIso8601String();
      });
    }
  }

// Método para escolher arquivos
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  // Método para remover arquivo
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _resetSuccessAnimation() {
    _successController.reset();
  }

  Future<void> _sendingAudio() async {
    setState(() {
      isSending = true;
    });

    print(widget.userId);
    print(prefs?.getString('userId'));
    String? recordingId = prefs?.getString('recordingId');
    String? filePath = prefs?.getString('filePath');

    try {
      print(recordingId);
      await _recorder.sendRecording(recordingId, filePath, prefs!);
      print("Incidente reportado com sucesso.");
    } catch (e) {
      print("Erro ao enviar o incidente: $e");
    }

    setState(() {
      isSending = false;
      isSuccess = true;
      _descriptionController.clear();
      selectedDate = "Informe a data e hora";
      _selectedFiles.clear();
    });

    _resetSuccessAnimation();
  }

  Future<void> _sendLooseRecords() async {
    if (selectedDate == "Informe a data e hora") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecione uma data válida"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      setState(() {
        isSending = true;
      });

      try {
        for (var file in _selectedFiles) {
          final filePath = file.path;
          if (filePath != null) {
            final url = await FirebaseStorageService()
                .uploadFile(filePath, "loose_files");
            if (url != null) {
              urls.add(url);
            } else {
              throw Exception("Falha ao fazer upload do arquivo: ${file.name}");
            }
          }
        }

        if (urls.length == _selectedFiles.length) {
          // Envia os dados para o backend
          await _sendLooseRecord.sendLooseEmployeesRecording(
            userId: widget.userId,
            urls: urls,
            date: selectedDate,
            description: _descriptionController.text,
          );
        } else {
          throw Exception("Nem todos os arquivos foram enviados com sucesso.");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isSending = false;
          isSuccess = true;
          _descriptionController.clear();
          selectedDate = "Informe a data e hora";
        });

        _resetSuccessAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  backgroundColor: Color(0xFFC3C7FD),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.black,
                    ),
                    onPressed: () async {
                      await prefs?.remove("userId");
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    },
                  ),
                ),
                // Header com logo
                Container(
                  width: double.infinity,
                  color: Color(0xFFC3C7FD),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: Image.asset(
                          'assets/logo_avaguard.png',
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
                ValueListenableBuilder<bool>(
                  valueListenable: AudioRecord.isRecording,
                  builder: (context, isRecording, child) {
                    if (isRecording) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.mic,
                                        color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Gravação em andamento...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        if (prefs != null) {
                                          await _recorder
                                              .cancelRecording(prefs!);
                                          setState(
                                              () {}); // Atualiza a UI após o cancelamento
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Gravação cancelada com sucesso!"),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        setState(
                                            () {}); // Atualiza a UI após o cancelamento
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.red,
                                        child: const Icon(
                                          Icons.stop,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    GestureDetector(
                                      onTap: _sendingAudio,
                                      child: const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue,
                                        child: Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Data do incidente"),
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    margin: EdgeInsets.all(16.0),
                    child: TextField(
                      enabled: false,
                      controller: TextEditingController(text: selectedDate),
                      decoration: const InputDecoration(
                        labelText: "Informe a data",
                        prefixIcon: Icon(
                          Icons.date_range,
                          color: Color(0xFF5360F5),
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Descrição do ocorrido"),
                ),
                Container(
                  margin: EdgeInsets.all(16.0),
                  child: TextField(
                    maxLines: 5,
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: "Descreva o que aconteceu...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Envio de arquivos
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Envio de provas"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _pickFiles,
                    child: const Text("Escolher arquivos"),
                  ),
                ),

                const SizedBox(height: 8),

                // Exibição dos arquivos selecionados com estilo
                if (_selectedFiles.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Arquivos Selecionados:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          final fileExtension = file.extension ?? "file";
                          final fileSize =
                              (file.size / 1024).toStringAsFixed(2);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              leading: Icon(
                                _getFileIcon(fileExtension),
                                color: Colors.blue,
                                size: 40,
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text("$fileSize KB"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeFile(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  Center(
                    child: Column(
                      children: const [
                        Icon(
                          Icons.folder_open,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Nenhum arquivo selecionado.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Botão de envio
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 50.0),
                    child: ElevatedButton(
                      onPressed:
                          _selectedFiles.isNotEmpty ? _sendLooseRecords : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedFiles.isNotEmpty
                            ? const Color(0xFF5360F5)
                            : Colors.grey, // Cor do botão desativado
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Enviar",
                        style: TextStyle(
                          color: _selectedFiles.isNotEmpty
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSending)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/sending.json', // Animação de envio
                      width: 150,
                      height: 150,
                      repeat: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Enviando...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isSuccess)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Lottie.asset(
                  'assets/success.json',
                  width: 250,
                  height: 250,
                  controller: _successController, // Associa o controlador
                  onLoaded: (composition) {
                    setState(() {
                      _successController.duration =
                          composition.duration; // Define a duração
                      _successController.forward(); // Inicia a animação
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
