import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../consts.dart';

class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({super.key});
  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  String? _status;
  bool _checking = false;

  Future<void> _check() async {
    setState(() { _checking = true; _status = null; });
    final url = Uri.parse('${AppConsts.effectiveBaseUrl.replaceAll('/api/v1', '')}/health');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        setState(() => _status = '✅ Conectado a ${AppConsts.effectiveBaseUrl} (${res.body})');
      } else {
        setState(() => _status = '⚠️ Servidor responde ${res.statusCode} en $url');
      }
    } catch (e) {
      // try alt
      try {
        final r2 = await http.get(Uri.parse('${AppConsts.effectiveBaseUrl}/users/search?q=test&excludeUid=0')).timeout(const Duration(seconds: 5));
        setState(() => _status = '✅ API responde (${r2.statusCode}) en ${AppConsts.effectiveBaseUrl}');
      } catch (e2) {
        setState(() => _status = '❌ Sin conexión a ${AppConsts.effectiveBaseUrl}\n$e\n→ Ejecuta: cd server && npm run dev');
      }
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _check()); }

  void _useLanIp() {
    // IP detectada en tu PC ahora mismo
    const lanIp = 'http://192.168.3.53:3000/api/v1';
    AppConsts.overrideUrl = _normalizeApiUrl(lanIp);
    _check();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API cambiada a $lanIp'), backgroundColor: const Color(0xFF25D366)));
  }

  void _useUsb() {
    const usbUrl = 'http://127.0.0.1:3000/api/v1';
    AppConsts.overrideUrl = usbUrl;
    _check();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API configurada por USB (adb reverse)'), backgroundColor: Color(0xFF25D366)),
    );
  }

  void _showEditDialog() {
    final ctrl = TextEditingController(text: AppConsts.effectiveBaseUrl);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Configurar API'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'http://IP:3000/api/v1', border: OutlineInputBorder()), keyboardType: TextInputType.url),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          final value = _normalizeApiUrl(ctrl.text);
          if (value == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Introduce una URL válida, por ejemplo http://192.168.3.58:3000/api/v1')),
            );
            return;
          }
          AppConsts.overrideUrl = value;
          Navigator.pop(context);
          _check();
        }, child: const Text('Guardar')),
      ],
    ));
  }

  String? _normalizeApiUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final path = uri.path.isEmpty || uri.path == '/'
        ? '/api/v1'
        : uri.path.replaceFirst(RegExp(r'/+$'), '');
    final port = uri.hasPort ? uri.port : 3000;
    return uri.replace(port: port, path: path).toString();
  }

  @override
  Widget build(BuildContext context) {
    final isFail = _status?.startsWith('❌') == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _status?.startsWith('✅') == true ? const Color(0xFFE6F4EA) : isFail ? const Color(0xFFFCE8E6) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _status?.startsWith('✅') == true ? const Color(0xFF25D366) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('API: ${AppConsts.effectiveBaseUrl}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF54656F)))),
            if (_checking) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            if (!_checking) IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _check, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: _showEditDialog, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
          if (_status != null) ...[
            const SizedBox(height: 4),
            Text(_status!, style: TextStyle(fontSize: 12, color: _status!.startsWith('✅') ? const Color(0xFF137333) : isFail ? const Color(0xFFA50E0E) : const Color(0xFF775500))),
          ],
          if (isFail) ...[
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _useUsb,
              icon: const Icon(Icons.usb, size: 16),
              label: const Text('Usar conexión USB', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(height: 4),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _useLanIp,
              icon: const Icon(Icons.wifi, size: 16),
              label: const Text('Usar IP física 192.168.3.53', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(height: 4),
            Text('USB requiere adb reverse. La IP física requiere que ambos dispositivos estén en la misma red.', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }
}
