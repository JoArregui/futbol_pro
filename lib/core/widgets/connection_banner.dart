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
    const lanIp = 'http://192.168.3.58:3000/api/v1';
    AppConsts.overrideUrl = lanIp;
    _check();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API cambiada a $lanIp'), backgroundColor: const Color(0xFF25D366)));
  }

  void _showEditDialog() {
    final ctrl = TextEditingController(text: AppConsts.effectiveBaseUrl);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Configurar API'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'http://IP:3000/api/v1', border: OutlineInputBorder()), keyboardType: TextInputType.url),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () { AppConsts.overrideUrl = ctrl.text.trim(); Navigator.pop(context); _check(); }, child: const Text('Guardar')),
      ],
    ));
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
              onPressed: _useLanIp,
              icon: const Icon(Icons.wifi, size: 16),
              label: const Text('Usar IP física 192.168.3.58', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(height: 4),
            Text('Si estás en móvil físico, 10.0.2.2 solo funciona en emulador. Pulsa el botón.', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }
}
