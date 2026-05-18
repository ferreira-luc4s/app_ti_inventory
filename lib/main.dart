import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TI Inventory',
      theme: ThemeData(

        brightness: Brightness.dark,
        

        scaffoldBackgroundColor: Colors.black,
        

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark, 
          surface: Colors.grey[900],   
        ),
        

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// --- TELA DE LOGIN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false; 

  
  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar('Preencha todos os campos!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://mobile-ios-login.zani0x03.eti.br/api/auth/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text,
          'password': _passController.text,
          'sistemaId': 'd6d0ec99-099c-4523-999f-aba9edceb925', 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['access_token']; 
        
        debugPrint('Login realizado com sucesso! Token: $token');

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(token: token)),
        );
      } else {
        _showSnackBar('Usuário ou senha incorretos!');
      }
    } catch (e) {
      _showSnackBar('Erro ao conectar no servidor: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.inventory, size: 120, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'TI Inventory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuário',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TELA INICIAL ---
class HomePage extends StatefulWidget {
  final String token; // Recebe o token do login

  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _itens = [];

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  void _atualizarLista() async {
    final dados = await DatabaseHelper.getItems();
    setState(() {
      _itens = dados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Inventário'), 
        centerTitle: true,
      ),
      
      // --- INÍCIO DO MENU HAMBÚRGUER ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(5),
                      color: Colors.blue, 
                      child: Image.asset(
                        'assets/logo.png', 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('TI INVENTORY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: Colors.blue),
              title: const Text('Chat de Atendimento'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatPage(token: widget.token)),                );
              },
            ),
            const Divider(), 
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: ListView.builder(
        itemCount: _itens.length,
        itemBuilder: (context, index) {
          final item = _itens[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.devices, color: Colors.blue),
              title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailsPage(
                      id: item['id'],
                      nome: item['nome'],
                      imagemPath: item['imagem_path'],
                    ),
                  ),
                );
                _atualizarLista();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryPage()),
          );
          _atualizarLista();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- TELA CHAT DE ATENDIMENTO (CONECTADA À API) ---
class ChatPage extends StatefulWidget {
  final String token; // Recebe o token necessário para a API

  const ChatPage({super.key, required this.token});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Controlador para auto-scroll
  final List<Map<String, String>> _mensagens = []; // Armazena o histórico do chat na tela
  bool _enviando = false;

  // Função para rolar a tela até a última mensagem
  void _irParaOFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensagem() async {
    final texto = _msgController.text.trim();
    if (texto.isEmpty || _enviando) return;

    // Adiciona a mensagem do usuário na tela imediatamente
    setState(() {
      _mensagens.add({'remetente': 'user', 'texto': texto});
      _enviando = true;
    });
    _msgController.clear();
    _irParaOFinal(); // Rola para baixo

    try {
      final url = Uri.parse('https://mobile-ios-ia.zani0x03.eti.br/api/ai/chat');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'prompt': texto,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final respostaIa = data['response'] ?? response.body; 

        setState(() {
          _mensagens.add({'remetente': 'ia', 'texto': respostaIa.toString()});
        });
      } else {
        setState(() {
          _mensagens.add({'remetente': 'ia', 'texto': 'Erro do servidor (Status ${response.statusCode}).'});
        });
      }
    } catch (e) {
      setState(() {
        _mensagens.add({'remetente': 'ia', 'texto': 'Erro de conexão: $e'});
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
      _irParaOFinal(); // Rola para baixo após a resposta da IA
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suporte de TI')),
      body: Column(
        children: [
          // Área de Mensagens
          Expanded(
            child: _mensagens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Como podemos ajudar hoje?', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController, // Vincula o controlador de scroll
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensagens.length,
                    itemBuilder: (context, index) {
                      final msg = _mensagens[index];
                      final bUser = msg['remetente'] == 'user';
                      
                      return Align(
                        alignment: bUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bUser ? Colors.blue[700] : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12).copyWith(
                              bottomRight: bUser ? const Radius.circular(0) : const Radius.circular(12),
                              bottomLeft: bUser ? const Radius.circular(12) : const Radius.circular(0),
                            ),
                          ),
                          child: Text(
                            msg['texto'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Indicador de digitação/carregamento da IA
          if (_enviando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          // Campo de Entrada de Texto protegido contra sobreposição do sistema
          SafeArea(
            top: false, // Só protege a parte de baixo da tela
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _enviarMensagem(),
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _enviarMensagem,
                    icon: const Icon(Icons.send, color: Colors.blue),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TELA ADICIONAR ITEM ---
class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final TextEditingController _nomeController = TextEditingController();
  File? _imagemSelecionada;

  Future<void> _pegarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: source);

    if (foto != null) {
      setState(() {
        _imagemSelecionada = File(foto.path);
      });
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context); 
                  _pegarImagem(ImageSource.gallery); 
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tirar Foto Agora'),
                onTap: () {
                  Navigator.pop(context); 
                  _pegarImagem(ImageSource.camera); 
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Equipamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Foto do Aparelho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GestureDetector(
              // 3. Agora o toque chama o MENU de opções
              onTap: _mostrarOpcoesFoto, 
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: _imagemSelecionada == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search, size: 50, color: Colors.blue),
                          Text('Toque para adicionar foto'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Equipamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_imagemSelecionada == null || _nomeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adicione uma foto e dê um nome!')),
                  );
                  return;
                }

                await DatabaseHelper.insertItem(
                  _nomeController.text, 
                  _imagemSelecionada!.path 
                );

                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 11, 133, 0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Salvar no Inventário'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DE DETALHES DO EQUIPAMENTO ---
class ItemDetailsPage extends StatefulWidget {
  final int id;
  final String nome;
  final String? imagemPath;

  const ItemDetailsPage({super.key, required this.id, required this.nome, this.imagemPath});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  late String nomeExibicao;
  String? imagemExibicao; // Adicione esta linha

  @override
  void initState() {
    super.initState();
    nomeExibicao = widget.nome;
    imagemExibicao = widget.imagemPath; // Inicia com a imagem que veio do banco
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nomeExibicao)),
      body: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[900],
            // No seu Container de imagem, altere para:
            child: imagemExibicao != null
                ? Image.file(File(imagemExibicao!), fit: BoxFit.cover)
                : const Icon(Icons.devices, size: 100, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeExibicao,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _abrirEditor, // Função para editar
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 154),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // CHAMADA DE EXCLUSÃO
                          await DatabaseHelper.deleteItem(widget.id);
                          if (mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 124, 0, 12),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirEditor() {
      final controller = TextEditingController(text: nomeExibicao);
      String? novoCaminhoImagem = imagemExibicao; // Variável temporária para o modal

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder( // StatefulBuilder permite atualizar o modal
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Editar Equipamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Novo Nome'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() {
                        novoCaminhoImagem = image.path;
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Trocar Foto'),
                ),
                if (novoCaminhoImagem != null)
                  const Text("Nova foto selecionada", style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  // ATENÇÃO: Verifique se seu DatabaseHelper.updateItem aceita o 3º parâmetro (imagem)
                  await DatabaseHelper.updateItem(widget.id, controller.text, novoCaminhoImagem);
                  
                  setState(() {
                    nomeExibicao = controller.text;
                    imagemExibicao = novoCaminhoImagem; // Atualiza a foto na tela principal
                  });
                  
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      );
    }
  }