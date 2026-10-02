import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MedidorApp());

class MedidorApp extends StatelessWidget {
  const MedidorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medidor IoT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String resistencia = "---";
  String bateria = "---";
  String tiempoCarga = "---";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    conectarMQTT();
  }

  Future<void> conectarMQTT() async {
    final client = MqttBrowserClient('wss://broker.hivemq.com/mqtt',
        'flutter_web_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 8884;
    client.keepAlivePeriod = 60;

    try {
      await client.connect();
      setState(() {
        isConnected = true;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
      client.disconnect();
      return;
    }

    client.subscribe('proyectoR/resistencia', MqttQos.atLeastOnce);
    client.subscribe('proyectoR/bateria', MqttQos.atLeastOnce);
    client.subscribe('proyectoR/tiempo', MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      setState(() {
        if (topic == 'proyectoR/resistencia') resistencia = payload;
        if (topic == 'proyectoR/bateria') bateria = payload;
        if (topic == 'proyectoR/tiempo') tiempoCarga = payload;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'MEDIDOR DE RESISTENCIA IoT',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 16,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: isConnected ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'Online' : 'Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitoreo en Tiempo Real',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta Principal: Resistencia (Máximo 1 Ohm)
              _buildMetricCard(
                title: 'Resistencia Medida',
                value: resistencia,
                unit: 'Ω',
                icon: Icons.speed,
                accentColor: const Color(0xFF38BDF8),
                isPrimary: true,
              ),
              const SizedBox(height: 12),

              // Tarjetas Secundarias: Batería y Tiempo
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Batería',
                      value: bateria,
                      unit: '%',
                      icon: Icons.battery_charging_full_rounded,
                      accentColor: const Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Tiempo Carga',
                      value: tiempoCarga,
                      unit: 'min',
                      icon: Icons.timer_rounded,
                      accentColor: const Color(0xFFFACC15),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isPrimary ? 20.0 : 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isPrimary ? 15 : 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: accentColor, size: isPrimary ? 26 : 20),
            ],
          ),
          SizedBox(height: isPrimary ? 12 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isPrimary ? 38 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: isPrimary ? 18 : 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
