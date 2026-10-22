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
        '/arbitrios': (context) => ArbitriosScreen(idContri: ModalRoute.of(context)!.settings.arguments as String? ?? ""),
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
  bool _obscurePassword = true; // 👈 Variable para controlar la visibilidad

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
                obscureText: _obscurePassword, // 👈 Se conecta a la variable de estado
                decoration: InputDecoration(
                  labelText: "Clave de Acceso (RUC/LE)",
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  // 👈 Agregamos el botón del "ojito" aquí:
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword; // Alterna el estado
                      });
                    },
                  ),
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
              onPressed: () => Navigator.pushNamed(context, '/arbitrios', arguments: usuarioId),
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
// 4. PANTALLA DE CONTROL ARBITRIOS (CON TABS)
// ==========================================
import 'package:flutter/material.dart';
// Importa tu servicio HTTP o controlador de API
// import '../services/api_service.dart';

class ArbitriosScreen extends StatefulWidget {
  final String idContri; // Recibido desde el login o menú principal

  const ArbitriosScreen({Key? key, required this.idContri}) : super(key: key);

  @override
  State<ArbitriosScreen> createState() => _ArbitriosScreenState();
}

class _ArbitriosScreenState extends State<ArbitriosScreen> {
  bool isLoading = true;
  String? rucLe;
  String errorMessage = "";

  // Listas y datos para los arbitrios
  List<dynamic> listaPredios = [];
  String? predioSeleccionadoId;
  Map<String, dynamic>? resumenDeuda;
  List<dynamic> mesesPendientes = [];

  @override
  void initState() {
    super.initState();
    _inicializarDatosContribuyente();
  }

  // Paso 1: Ejecutar la obtención de datos con el id_contri para extraer ruc_le
  Future<void> _inicializarDatosContribuyente() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      print("Consultando datos para id_contri: ${widget.idContri}");
      
      // Llamada a tu API que ejecuta el SP de SQL Server (_ObtieneDatosContribuxID_sp)
      // Ejemplo: final resultado = await ApiService.obtenerDatosContribuyente(widget.idContri);
      
      // Simulación de la respuesta obtenida del procedimiento:
      // rucLe = resultado['ruc_le']; 

      if (rucLe != null && rucLe!.isNotEmpty) {
        // Paso 2: Con el ruc_le obtenido, cargamos los predios o deudas de arbitrios
        await _cargarPrediosYArbitrios(rucLe!);
      } else {
        setState(() {
          errorMessage = "No se encontró el RUC/LE para este contribuyente.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error al conectar con el servidor: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _cargarPrediosYArbitrios(String ruc) async {
    try {
      // Aquí llamas a los siguientes procedimientos usando el rucLe
      // listaPredios = await ApiService.getPrediosPorRuc(ruc);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error al cargar los predios: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estado de Pagos de Arbitrios"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar información del RUC recuperado (opcional para depuración o UI)
                      Text(
                        "RUC / LE: ${rucLe ?? 'No disponible'}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Selector de Predios
                      const Text(
                        "Seleccione un Predio:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: const Text("-- Seleccione un predio --"),
                        value: predioSeleccionadoId,
                        items: listaPredios.map((predio) {
                          return DropdownMenuItem<String>(
                            value: predio['id'].toString(),
                            child: Text("${predio['codigo']} - ${predio['direccion']}"),
                          );
                        }).toList(),
                        onChanged: (nuevoId) {
                          setState(() {
                            predioSeleccionadoId = nuevoId;
                          });
                          // Aquí disparas la consulta del resumen de deuda para el predio elegido
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      
                      // Resto de la interfaz para mostrar meses pendientes y pagos...
                      if (predioSeleccionadoId == null)
                        const Expanded(
                          child: Center(
                            child: Text("Seleccione un predio para ver el resumen de deudas."),
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(
                            child: Text("Aquí se muestra el resumen de deuda y meses pendientes."),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ==========================================
// 5. PANTALLA DE CONTROL PREDIAL Y TRIBUTOS (CON TABS)
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

  void _mostrarPrediosAnio(String anioFiscal, String usuarioId) async {
    // Mostrar indicador de carga emergente
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final response = await http.get(Uri.parse('$apiUrl/api/predios/$anioFiscal/$usuarioId'));
      
      // Cerrar el indicador de carga
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> predios = data["data"] ?? [];

        // Mostrar el BottomSheet con los predios obtenidos
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1E3A1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Predios del Año: $anioFiscal",
                        style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: predios.isEmpty
                            ? const Center(child: Text("No se encontraron predios para este período.", style: TextStyle(color: Colors.white70)))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: predios.length,
                                itemBuilder: (context, index) {
                                final p = predios[index];
                                return Card(
                                  color: Colors.black26,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['Nombre_Predio'] ?? p['DIRECCION'] ?? 'Inmueble',
                                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 6),
                                        // Etiquetas en amarillo bajito (Colors.amber[200]) y datos en blanco
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 13),
                                            children: [
                                              TextSpan(text: "Tipo: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Tipo_Predio'] ?? 'N/A'}\n", style: const TextStyle(color: Colors.white)),
                                              TextSpan(text: "Dirección: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Direccion'] ?? 'N/A'}\n", style: const TextStyle(color: Colors.white)),
                                              TextSpan(text: "Sector: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Sector'] ?? 'N/A'}\n", style: const TextStyle(color: Colors.white)),
                                              TextSpan(text: "Área Terreno: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Area_Terreno'] ?? '0'}\n", style: const TextStyle(color: Colors.white)),
                                              TextSpan(text: "Área Construida: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Area_Construida'] ?? '0'}\n", style: const TextStyle(color: Colors.white)),
                                              TextSpan(text: "Condición: ", style: TextStyle(color: Colors.amber[200], fontWeight: FontWeight.bold)),
                                              TextSpan(text: "${p['Condicion'] ?? 'N/A'}", style: const TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const Divider(color: Colors.white12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("Autoavalúo Total:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text("S/. ${p['Total_Autoavaluo'] ?? '0.00'}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                           ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      } else {
        _mostrarAlertaError("Error", "No se pudo cargar la lista de predios.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarAlertaError("Error de Conexión", e.toString());
    }
  }

  void _mostrarAlertaError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar"))],
      ),
    );
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
                      "Período: $anioFiscal",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF0D3B0D),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.home_work_rounded, size: 16),
                      label: const Text("Predios", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
                        _mostrarPrediosAnio(usuarioId, anioFiscal.toString());
                      },
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

  // Vista especializada y ordenada para los Pagados
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
        
        // Extrayendo los campos de pagados con alternativas por si varía el nombre exacto de la columna SQL
        final anioFiscal = item['Año_Fiscal'] ?? item['ANO'] ?? item['ANIO_FISCAL'] ?? item['PERIODO'] ?? 'N/A';
        final baseImponible = item['BaseImponible'] ?? item['BASEIMP'] ?? '0.00';
        final impuesto = item['Impuesto'] ?? item['IMPVAL'] ?? '0.00';
        final automatizacion = item['Automatizacion'] ?? item['AUTOS'] ?? '0.00';
        final reajustes = item['Reajuste'] ?? item['REAJUSTES'] ?? '0.00';
        final intereses = item['Intereses'] ?? item['INTERESES'] ?? '0.00';
        final fechaPago = item['Fecha_pago'] ?? item['FECHA'] ?? item['F_PAGO'] ?? 'N/A';
        final vcajaNro = item['Caja_Nro'] ?? item['CAJA'] ?? item['NRO_CAJA'] ?? 'N/A';
        final totalCancelado = item['Total_Cancelado'] ?? item['TOTAL'] ?? item['MONTO'] ?? '0.00';

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
                      "Período: $anioFiscal",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF0D3B0D),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.home_work_rounded, size: 16),
                      label: const Text("Predios", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final String usuarioId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
                        _mostrarPrediosAnio(usuarioId, anioFiscal.toString());
                      },
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
                const SizedBox(height: 4),
                Text("Fecha de Pago: $fechaPago", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text("VCaja Nro.: $vcajaNro", style: const TextStyle(fontSize: 14)),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Cancelado:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("S/. $totalCancelado", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
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
