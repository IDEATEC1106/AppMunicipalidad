import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// URL de tu API backend intermedia
const String apiUrl = "https://38.224.68.171:5001";

void main() {
  // Ignorar certificados autofirmados si usas IP directa con HTTPS
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MunicipalidadApp());
}

// Clase para permitir certificados autofirmados en desarrollo
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MunicipalidadApp extends StatelessWidget {
  const MunicipalidadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Municipalidad de Guadalupe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0D3B0D), // Verde institucional
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/menu': (context) => const MenuScreen(),
        '/datos': (context) => const DatosScreen(),
        '/predial': (context) => const PredialScreen(),
      },
    );
  }
}

// ==========================================
// 1. PANTALLA DE LOGIN (Con Estado Correcto)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final usuario = _userController.text.trim();
    final clave = _passController.text.trim();

    if (usuario.isEmpty || clave.isEmpty) {
      _mostrarAlerta("Campos Vacíos", "Por favor, ingrese su código y clave.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_contri": usuario, "ruc_le": clave}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/menu', arguments: usuario);
        } else {
          _mostrarAlerta("Acceso Denegado", "Datos incorrectos.");
        }
      } else {
        _mostrarAlerta("Error", "Servidor no disponible temporalmente.");
      }
    } catch (e) {
      _mostrarAlerta("Error de Red", "No se pudo conectar al servidor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B0D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Escudo de la Municipalidad
              Image.asset(
                'escudo3_MDG.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "MUNICIPALIDAD DISTRITAL DE GUADALUPE",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "Acceso al Contribuyente",
                style: TextStyle(fontSize: 16, color: Color(0xFFFFD700), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: "Código de Contribuyente",
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Clave de Acceso (RUC/LE)",
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0D3B0D),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("CONECTAR E INGRESAR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. MENÚ PRINCIPAL
// ==========================================
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B0D),
      appBar: AppBar(
        title: const Text("MENÚ PRINCIPAL"),
        backgroundColor: const Color(0xFF0D3B0D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Bienvenido: Contribuyente #$usuarioId", style: const TextStyle(color: Colors.amber, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/datos', arguments: usuarioId),
              child: const Text("1. DATOS DEL CONTRIBUYENTE"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {},
              child: const Text("2. ESTADO DE PAGOS DE ARBITRIOS"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/predial', arguments: usuarioId),
              child: const Text("3. CONTROL PAGOS IMPUESTO PREDIAL"),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text("4. SALIR DEL SISTEMA"),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA DE DATOS DEL CONTRIBUYENTE
// ==========================================
class DatosScreen extends StatefulWidget {
  const DatosScreen({super.key});

  @override
  State<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends State<DatosScreen> {
  Map<String, dynamic> datosContribuyente = {};
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
    _cargarDatos(usuarioId);
  }

  Future<void> _cargarDatos(String usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/api/contribuyente/$usuarioId'));
      if (response.statusCode == 200) {
        setState(() {
          datosContribuyente = jsonDecode(response.body)["data"] ?? {};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Datos del Contribuyente")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: datosContribuyente.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key.toUpperCase(), style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    subtitle: Text(entry.value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ==========================================
// 4. PANTALLA DE CONTROL PREDIAL
// ==========================================
class PredialScreen extends StatelessWidget {
  const PredialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control Impuesto Predial")),
      body: const Center(
        child: Text("Módulo de Predios configurado de forma estable en Flutter."),
      ),
    );
  }
}
