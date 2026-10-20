import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// URL de tu API backend intermediaria
const String apiUrl = "http://38.224.68.171:5001";

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MunicipalidadApp());
}

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
        colorSchemeSeed: const Color(0xFF0D3B0D),
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
// 1. PANTALLA DE LOGIN
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
          _mostrarAlerta("Acceso Denegado", data["message"] ?? "Datos incorrectos.");
        }
      } else {
        _mostrarAlerta("Respuesta del Servidor", "Código: ${response.statusCode}\nCuerpo: ${response.body}");
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
      _cargarDatos(usuarioId);
    });
  }

  Future<void> _cargarDatos(String usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/api/contribuyente/$usuarioId'));
      if (response.statusCode == 200) {
        setState(() {
          datosContribuyente = jsonDecode(response.body)["data"] ?? {};
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
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
// 4. PANTALLA DE CONTROL PREDIAL Y TRIBUTOS (CON TABS)
// ==========================================
class PredialScreen extends StatefulWidget {
  const PredialScreen({super.key});

  @override
  State<PredialScreen> createState() => _PredialScreenState();
}

class _PredialScreenState extends State<PredialScreen> {
  List<dynamic> listaPendientes = [];
  List<dynamic> listaPagados = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
    _cargarDatosCuenta(usuarioId);
  }

  Future<void> _cargarDatosCuenta(String usuarioId) async {
    try {
      final resPen = await http.get(Uri.parse('$apiUrl/api/ctacte/pendientes/$usuarioId'));
      final resPag = await http.get(Uri.parse('$apiUrl/api/ctacte/pagados/$usuarioId'));

      if (resPen.statusCode == 200 && resPag.statusCode == 200) {
        final dataPen = jsonDecode(resPen.body);
        final dataPag = jsonDecode(resPag.body);

        setState(() {
          listaPendientes = dataPen["data"] ?? [];
          listaPagados = dataPag["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Vista especializada y ordenada para los Pendientes
  Widget _buildListaPendientes() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (listaPendientes.isEmpty) {
      return const Center(child: Text("No hay tributos pendientes de pago.", style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listaPendientes.length,
      itemBuilder: (context, index) {
        final item = listaPendientes[index];
        
        // Extrayendo los campos ordenados (ajustable según los nombres exactos de columnas que devuelva tu procedimiento almacenado)
        final anioFiscal = item['Año_Fiscal'] ?? item['ANO'] ?? item['ANIO_FISCAL'] ?? item['PERIODO'] ?? 'N/A';
        final baseImponible = item['BaseImponible'] ?? item['BASEIMP'] ?? '0.00';
        final impuesto = item['Impuesto'] ?? item['IMPVAL'] ?? '0.00';
        final automatizacion = item['Automatizacion'] ?? item['AUTOS'] ?? '0.00';
        final reajustes = item['Reajuste'] ?? item['REAJUSTES'] ?? '0.00';
        final intereses = item['Intereses'] ?? item['INTERESES'] ?? '0.00';
        final totalPendiente = item['Total_Pendiente'] ?? item['TOTAL_PAGO'] ?? item['SALDO'] ?? '0.00';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Año / Período: $anioFiscal",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Chip(
                      backgroundColor: Color(0x33FF5252),
                      label: Text(
                        "Pendiente",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Text("Base Imponible: S/. $baseImponible", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text("Impuesto: S/. $impuesto", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text("Automatización: S/. $automatizacion", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text("Reajustes: S/. $reajustes", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text("Intereses: S/. $intereses", style: const TextStyle(fontSize: 14)),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Pendiente:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("S/. $totalPendiente", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Vista genérica limpia para los Pagados
  Widget _buildListaPagados() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (listaPagados.isEmpty) {
      return const Center(child: Text("No hay registros de pagos anteriores.", style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listaPagados.length,
      itemBuilder: (context, index) {
        final item = listaPagados[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Registro de Pago", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    Chip(
                      backgroundColor: Color(0x3369F0AE),
                      label: Text("Pagado", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...item.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text("${entry.key}: ${entry.value}", style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Control de Pagos y Tributos"),
          backgroundColor: const Color(0xFF0D3B0D),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFFD700),
            labelColor: Color(0xFFFFD700),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "Pendientes"),
              Tab(icon: Icon(Icons.check_circle_outline), text: "Realizados"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListaPendientes(),
            _buildListaPagados(),
          ],
        ),
      ),
    );
  }
}
