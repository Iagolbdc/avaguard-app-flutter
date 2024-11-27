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
  String description = "";
  String selectedFile = "";
  bool isSending = false;
  bool isSuccess = false;
  late AnimationController _successController;
  bool hasPendingAudio = true; // Controle da exibição do aviso
  SharedPreferences? prefs;

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
    // Reinicia o AnimationController antes de iniciar a animação
    _successController.reset();
  }

  // Método para mostrar animação de envio
  Future<void> _sendingAudio() async {
    setState(() {
      isSending = true;
    });

    print(widget.userId);
    String? recordingId = prefs?.getString('recordingId');
    String? filePath = prefs?.getString('filePath');
    // Enviar gravação para o backend
    try {
      print(recordingId);
      await _recorder.sendRecording(description, recordingId, filePath);
      print("Incidente reportado com sucesso.");
    } catch (e) {
      print("Erro ao enviar o incidente: $e");
    }

    setState(() {
      isSending = false;
      isSuccess = true;
      hasPendingAudio = false; // Remove o aviso
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
                  leading: Container(
                    child: IconButton(
                      icon: Icon(
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
                SizedBox(height: 50),
                // Aviso de áudio pendente
                if (hasPendingAudio)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Colors.yellow[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.black),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Você tem um áudio pendente pronto para envio.",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Campo para data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Data do incidente"),
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    margin: EdgeInsets.all(16.0),
                    child: TextField(
                      enabled: false,
                      controller: TextEditingController(text: selectedDate),
                      decoration: InputDecoration(
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

                // Descrição do incidente
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Descrição do ocorrido"),
                ),
                Container(
                  margin: EdgeInsets.all(16.0),
                  child: TextField(
                    maxLines: 5,
                    onChanged: (value) {
                      setState(() {
                        description = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Descreva o que aconteceu...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Envio de arquivos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Envio de provas"),
                ),
                Container(
                  margin: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    child: Text("Escolha um arquivo"),
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
                    margin: EdgeInsets.symmetric(vertical: 50.0),
                    child: ElevatedButton(
                      onPressed: _sendingAudio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5360F5),
                        minimumSize: Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Enviar"),
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
                    SizedBox(height: 16),
                    Text(
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
