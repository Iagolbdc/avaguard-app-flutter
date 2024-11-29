import 'package:avaguard/audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String selectedFile = "";
  bool isSending = false;
  bool isSuccess = false;
  late AnimationController _successController;
  SharedPreferences? prefs;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
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
    //print("Gravação pendente: ${AudioRecord.hasPendingAudio}");
    if (pickedDate != null) {
      setState(() {
        selectedDate =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  // Método para escolher arquivo
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.single.name;
      });
    }
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
      await _recorder.sendRecording(recordingId, filePath);
      print("Incidente reportado com sucesso.");
    } catch (e) {
      print("Erro ao enviar o incidente: $e");
    }

    setState(() {
      isSending = false;
      isSuccess = true;
      _descriptionController.clear();
      selectedDate = "Informe a data e hora";
    });

    _resetSuccessAnimation();
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          color: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.mic, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Gravação em andamento...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                // ValueListenableBuilder(
                //     valueListenable: AudioRecord.hasPendingAudio,
                //     builder: (context, hasPendingAudio, child) {
                //       if (hasPendingAudio) {
                //         return Padding(
                //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //           child: Card(
                //             color: Colors.yellow[700],
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             child: Padding(
                //               padding: const EdgeInsets.all(12.0),
                //               child: Row(
                //                 children: [
                //                   Icon(Icons.warning, color: Colors.black),
                //                   SizedBox(width: 8),
                //                   Expanded(
                //                     child: Text(
                //                       "Você tem um áudio pendente pronto para envio.",
                //                       style: TextStyle(
                //                         color: Colors.black,
                //                         fontWeight: FontWeight.bold,
                //                       ),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         );
                //       }
                //       return const SizedBox.shrink();
                //     }),
                // Campo para data
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
                Container(
                  margin: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text("Escolha um arquivo"),
                  ),
                ),
                if (selectedFile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Item selecionado: $selectedFile"),
                  ),

                // Botão de envio
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 50.0),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: AudioRecord.isRecording,
                      builder: (context, isRecording, child) {
                        return ElevatedButton(
                          onPressed: isRecording
                              ? _sendingAudio
                              : null, // Desabilita se não houver áudio pendente
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRecording
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
                              color:
                                  isRecording ? Colors.white : Colors.black54,
                            ),
                          ),
                        );
                      },
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
