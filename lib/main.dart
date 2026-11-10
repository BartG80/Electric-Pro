import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppConfig {
  static const String appName = 'Preventivo Elettrico Pro';
  static const String package = 'com.tuosito.elettricopro';
  static const List<String> categorie = ['Impianto', 'Quadro', 'Illuminazione', 'Domotica', 'Riparazione', 'Cavi'];
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange, brightness: Brightness.light),
      home: const HomeScreen(),
    );
  }
}

// ---------- MODELLO LAVORO ----------
class Lavoro {
  final String nome;
  final String categoria;
  double prezzo; // NON FINAL - così si può cambiare il prezzo base
  final String unita;
  Lavoro(this.nome, this.categoria, this.prezzo, {this.unita = 'cad.'});
}

final List<Lavoro> catalogo = [
  Lavoro('Sopralluogo / Uscita', 'Riparazione', 50),
  Lavoro('Punto luce', 'Impianto', 45),
  Lavoro('Punto presa 16A', 'Impianto', 50),
  Lavoro('Punto TV / Dati / Telefono', 'Impianto', 60),
  Lavoro('Impianto elettrico nuovo - a punto', 'Impianto', 65),
  Lavoro('Quadro elettrico - montaggio', 'Quadro', 350),
  Lavoro('Interruttore magnetotermico', 'Quadro', 80),
  Lavoro('Interruttore differenziale', 'Quadro', 90),
  Lavoro('Impianto di terra', 'Quadro', 250),
  Lavoro('Installazione lampadario / Plafoniera', 'Illuminazione', 40),
  Lavoro('Faretto LED incasso', 'Illuminazione', 55),
  Lavoro('Striscia LED - al metro', 'Illuminazione', 25, unita: 'mt'),
  Lavoro('Citofono', 'Domotica', 180),
  Lavoro('Videocitofono', 'Domotica', 350),
  Lavoro('Predisposizione condizionatore', 'Impianto', 180),
  Lavoro('Allarme - sensore', 'Domotica', 90),
  Lavoro('Domotica - punto / centralina', 'Domotica', 120),
  Lavoro('Certificazione / Dichiarazione di conformità', 'Riparazione', 150),
  Lavoro('Riparazione guasto / ricerca guasto', 'Riparazione', 70, unita: 'ora'),
  // MATASSE CAVO UNIPOLARE - 5 SEZIONI x 4 COLORI - CON - 1 +
  // --- 1,5 mm² ---
  Lavoro('Matassa cavo 1,5mm² - Blu - Neutro - 100m', 'Cavi', 45, unita: 'matassa'),
  Lavoro('Matassa cavo 1,5mm² - Marrone - Fase - 100m', 'Cavi', 45, unita: 'matassa'),
  Lavoro('Matassa cavo 1,5mm² - Nero - Fase - 100m', 'Cavi', 45, unita: 'matassa'),
  Lavoro('Matassa cavo 1,5mm² - Giallo Verde - Terra - 100m', 'Cavi', 45, unita: 'matassa'),
  // --- 2,5 mm² ---
  Lavoro('Matassa cavo 2,5mm² - Blu - Neutro - 100m', 'Cavi', 65, unita: 'matassa'),
  Lavoro('Matassa cavo 2,5mm² - Marrone - Fase - 100m', 'Cavi', 65, unita: 'matassa'),
  Lavoro('Matassa cavo 2,5mm² - Nero - Fase - 100m', 'Cavi', 65, unita: 'matassa'),
  Lavoro('Matassa cavo 2,5mm² - Giallo Verde - Terra - 100m', 'Cavi', 65, unita: 'matassa'),
  // --- 4 mm² ---
  Lavoro('Matassa cavo 4mm² - Blu - Neutro - 100m', 'Cavi', 95, unita: 'matassa'),
  Lavoro('Matassa cavo 4mm² - Marrone - Fase - 100m', 'Cavi', 95, unita: 'matassa'),
  Lavoro('Matassa cavo 4mm² - Nero - Fase - 100m', 'Cavi', 95, unita: 'matassa'),
  Lavoro('Matassa cavo 4mm² - Giallo Verde - Terra - 100m', 'Cavi', 95, unita: 'matassa'),
  // --- 6 mm² ---
  Lavoro('Matassa cavo 6mm² - Blu - Neutro - 100m', 'Cavi', 135, unita: 'matassa'),
  Lavoro('Matassa cavo 6mm² - Marrone - Fase - 100m', 'Cavi', 135, unita: 'matassa'),
  Lavoro('Matassa cavo 6mm² - Nero - Fase - 100m', 'Cavi', 135, unita: 'matassa'),
  Lavoro('Matassa cavo 6mm² - Giallo Verde - Terra - 100m', 'Cavi', 135, unita: 'matassa'),
  // --- 10 mm² ---
  Lavoro('Matassa cavo 10mm² - Blu - Neutro - 100m', 'Cavi', 210, unita: 'matassa'),
  Lavoro('Matassa cavo 10mm² - Marrone - Fase - 100m', 'Cavi', 210, unita: 'matassa'),
  Lavoro('Matassa cavo 10mm² - Nero - Fase - 100m', 'Cavi', 210, unita: 'matassa'),
  Lavoro('Matassa cavo 10mm² - Giallo Verde - Terra - 100m', 'Cavi', 210, unita: 'matassa'),
];

// ---------- MODELLO DITTA ----------
class Ditta {
  String nome, indirizzo, piva, telefono, email, cittaForo;
  Ditta({this.nome = '', this.indirizzo = '', this.piva = '', this.telefono = '', this.email = '', this.cittaForo = ''});
  bool get isEmpty => nome.isEmpty;
}

class RigaPreventivo {
  final Lavoro lavoro;
  int qty;
  double prezzoPersonalizzato;
  RigaPreventivo(this.lavoro, {this.qty = 1, double? prezzo}) : prezzoPersonalizzato = prezzo ?? lavoro.prezzo;
  double get totale => qty * prezzoPersonalizzato;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Ditta ditta = Ditta();
  final _clienteCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  String _filtroCategoria = 'Tutte';
  String _search = '';
  double _iva = 10;
  double _accontoPerc = 40;
  List<RigaPreventivo> righe = [];
  int _numero = 1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ditta = Ditta(
        nome: prefs.getString('ditta_nome') ?? '',
        indirizzo: prefs.getString('ditta_indirizzo') ?? '',
        piva: prefs.getString('ditta_piva') ?? '',
        telefono: prefs.getString('ditta_telefono') ?? '',
        email: prefs.getString('ditta_email') ?? '',
        cittaForo: prefs.getString('ditta_foro') ?? '',
      );
      _numero = prefs.getInt('numero_preventivo') ?? 1;
      _iva = prefs.getDouble('iva_default') ?? 10;
    });
    if (ditta.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostraDialogDitta(primaVolta: true));
    }
  }

  Future<void> _saveDitta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ditta_nome', ditta.nome);
    await prefs.setString('ditta_indirizzo', ditta.indirizzo);
    await prefs.setString('ditta_piva', ditta.piva);
    await prefs.setString('ditta_telefono', ditta.telefono);
    await prefs.setString('ditta_email', ditta.email);
    await prefs.setString('ditta_foro', ditta.cittaForo);
    await prefs.setDouble('iva_default', _iva);
  }

  Future<void> _mostraDialogDitta({bool primaVolta = false}) async {
    final nomeC = TextEditingController(text: ditta.nome);
    final indC = TextEditingController(text: ditta.indirizzo);
    final pivaC = TextEditingController(text: ditta.piva);
    final telC = TextEditingController(text: ditta.telefono);
    final emailC = TextEditingController(text: ditta.email);
    final foroC = TextEditingController(text: ditta.cittaForo);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: !primaVolta,
      builder: (ctx) => AlertDialog(
        title: Text(primaVolta ? 'Benvenuto in ELECTRIC PRO' : 'Dati della tua ditta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (primaVolta) const Text('Inserisci l\'intestazione che apparirà in tutti i preventivi. La potrai cambiare dopo.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome ditta *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: indC, decoration: const InputDecoration(labelText: 'Indirizzo', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: pivaC, decoration: const InputDecoration(labelText: 'P.IVA / C.F.', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: telC, decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: foroC, decoration: const InputDecoration(labelText: 'Città - Foro competente', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          if (!primaVolta) TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salva')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        ditta = Ditta(nome: nomeC.text.trim(), indirizzo: indC.text.trim(), piva: pivaC.text.trim(), telefono: telC.text.trim(), email: emailC.text.trim(), cittaForo: foroC.text.trim());
      });
      await _saveDitta();
    }
  }

  double get subtotale => righe.fold(0, (s, r) => s + r.totale);
  double get ivaImporto => subtotale * (_iva / 100);
  double get totale => subtotale + ivaImporto;
  double get acconto => totale * (_accontoPerc / 100);

  String get numeroFormattato => 'EP-${DateTime.now().year}-${_numero.toString().padLeft(3, '0')}';
  String fmt(double v) => NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2).format(v);

  void _aggiungi(Lavoro l) {
    setState(() {
      final esistente = righe.where((r) => r.lavoro.nome == l.nome).toList();
      if (esistente.isNotEmpty) {
        esistente.first.qty++;
      } else {
        righe.add(RigaPreventivo(l));
      }
    });
  }

  void _rimuoviUno(Lavoro l) {
    setState(() {
      final esistente = righe.where((r) => r.lavoro.nome == l.nome).toList();
      if (esistente.isNotEmpty) {
        if (esistente.first.qty > 1) {
          esistente.first.qty--;
        } else {
          righe.remove(esistente.first);
        }
      }
    });
  }

  // MODIFICA PREZZO BASE NEL CATALOGO - pressione lunga
  Future<void> _modificaPrezzoBase(Lavoro l) async {
    final ctrl = TextEditingController(text: l.prezzo.toStringAsFixed(0));
    final nuovo = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica prezzo base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Nuovo prezzo €', border: OutlineInputBorder(), prefixText: '€ ')),
            const SizedBox(height: 8),
            const Text('Questo diventa il nuovo prezzo base per le prossime volte.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))), child: const Text('Salva')),
        ],
      ),
    );
    if (nuovo != null && nuovo > 0) {
      setState(() {
        l.prezzo = nuovo;
        for (final r in righe.where((r) => r.lavoro.nome == l.nome)) {
          r.prezzoPersonalizzato = nuovo;
        }
      });
    }
  }

  // MODIFICA PREZZO SOLO PER QUESTA RIGA / QUESTO CLIENTE
  Future<void> _modificaPrezzoRiga(RigaPreventivo r) async {
    final ctrl = TextEditingController(text: r.prezzoPersonalizzato.toStringAsFixed(0));
    final nuovo = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica prezzo per questo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.lavoro.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prezzo per questo preventivo €', border: OutlineInputBorder(), prefixText: '€ ')),
            const SizedBox(height: 8),
            const Text('Il listino base non cambia, cambia solo questa riga.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))), child: const Text('Salva')),
        ],
      ),
    );
    if (nuovo != null && nuovo > 0) {
      setState(() => r.prezzoPersonalizzato = nuovo);
    }
  }

  void _nuovoPreventivo() {
    setState(() {
      righe.clear();
      _clienteCtrl.clear();
      _telefonoCtrl.clear();
      _indirizzoCtrl.clear();
      _search = '';
      _filtroCategoria = 'Tutte';
      _iva = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nuovo preventivo - tutto azzerato')));
  }

  void _cancellaLavorazioni() {
    setState(() => righe.clear());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lavorazioni cancellate')));
  }

  // CREA IL PDF E LO RESTITUISCE COME BYTES
  Future<Uint8List> _creaPdfBytes() async {
    final doc = pw.Document();
    final data = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final foro = ditta.cittaForo.isEmpty ? '________' : ditta.cittaForo;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(ditta.nome.isEmpty ? 'ELECTRIC PRO' : ditta.nome, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
          if (ditta.indirizzo.isNotEmpty) pw.Text(ditta.indirizzo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (ditta.piva.isNotEmpty) pw.Text('P.IVA / C.F.: ${ditta.piva}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (ditta.telefono.isNotEmpty) pw.Text('Tel: ${ditta.telefono}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (ditta.email.isNotEmpty) pw.Text('Email: ${ditta.email}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.orange, thickness: 2),
        ]),
        pw.SizedBox(height: 14),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('PREVENTIVO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('N. $numeroFormattato', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text('Data: $data', style: const pw.TextStyle(fontSize: 11)),
          ]),
        ]),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('CLIENTE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            pw.Text(_clienteCtrl.text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (_telefonoCtrl.text.isNotEmpty) pw.Text('Tel: ${_telefonoCtrl.text}', style: const pw.TextStyle(fontSize: 11)),
            if (_indirizzoCtrl.text.isNotEmpty) pw.Text('Lavoro presso: ${_indirizzoCtrl.text}', style: const pw.TextStyle(fontSize: 11)),
          ]),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(0.7), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1.2)},
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.orange50),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('DESCRIZIONE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('QTÀ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PREZZO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTALE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
              ],
            ),
            ...righe.map((r) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${r.lavoro.nome}\n${r.lavoro.categoria}', style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${r.qty} ${r.lavoro.unita}', style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(fmt(r.prezzoPersonalizzato), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(fmt(r.totale), style: const pw.TextStyle(fontSize: 10))),
                ])),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Subtotale: ${fmt(subtotale)}', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('IVA ${_iva.toStringAsFixed(0)}%: ${fmt(ivaImporto)}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text('TOTALE: ${fmt(totale)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
            pw.Text('Acconto ${_accontoPerc.toStringAsFixed(0)}%: ${fmt(acconto)}', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('Saldo a fine lavori: ${fmt(totale - acconto)}', style: const pw.TextStyle(fontSize: 11)),
          ]),
        ]),
        pw.SizedBox(height: 18),
        pw.Text('NOTE LEGALI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.orange900)),
        pw.SizedBox(height: 4),
        pw.Text(
          '1. Il presente preventivo ha validità di 30 giorni dalla data di emissione.\n'
          '2. I prezzi indicati sono comprensivi di IVA al ${_iva.toStringAsFixed(0)}% se non diversamente indicato.\n'
          '3. Acconto del ${_accontoPerc.toStringAsFixed(0)}% alla conferma, saldo a lavoro ultimato.\n'
          '4. Eventuali varianti o lavorazioni aggiuntive saranno concordate e approvate per iscritto prima dell\'esecuzione.\n'
          '5. I materiali utilizzati sono quelli indicati in preventivo, eventuali sostituzioni saranno concordate.\n'
          '6. Il presente documento non costituisce fattura.\n'
          '7. Per qualsiasi controversia è competente il Foro di $foro.',
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 24),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(children: [pw.Text('________________________', style: const pw.TextStyle(fontSize: 10)), pw.Text('Firma ditta', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))]),
          pw.Column(children: [pw.Text('________________________', style: const pw.TextStyle(fontSize: 10)), pw.Text('Firma cliente per accettazione', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))]),
        ]),
      ],
    ));
    return doc.save();
  }

  bool _datiValidi() {
    if (_clienteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci il nome del cliente')));
      return false;
    }
    if (righe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiungi almeno un lavoro')));
      return false;
    }
    return true;
  }

  Future<void> _avanzaNumero() async {
    final prefs = await SharedPreferences.getInstance();
    final nuovo = _numero + 1;
    await prefs.setInt('numero_preventivo', nuovo);
    setState(() => _numero = nuovo);
  }

  // 1. SOLO VEDERE IL PDF - IL NUMERO NON AVANZA
  Future<void> _generaPdf() async {
    if (!_datiValidi()) return;
    final bytes = await _creaPdfBytes();
    await Printing.layoutPdf(onLayout: (f) async => bytes);
  }

  // 2. SALVA + INVIA SU WHATSAPP - QUI IL NUMERO AVANZA
  Future<void> _salvaEInviaWhatsApp() async {
    if (!_datiValidi()) return;
    final numeroAttuale = numeroFormattato;
    final bytes = await _creaPdfBytes();
    final dir = await getTemporaryDirectory();
    final nomeFile = 'Preventivo_${numeroAttuale}_${_clienteCtrl.text.trim().replaceAll(' ', '_')}.pdf';
    final file = File('${dir.path}/$nomeFile');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ciao ${_clienteCtrl.text}, ti invio il preventivo $numeroAttuale - Totale ${fmt(totale)}. Fammi sapere se va bene. Grazie!',
      subject: 'Preventivo $numeroAttuale',
    );

    await _avanzaNumero();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preventivo $numeroAttuale inviato - prossimo sarà $numeroFormattato')));
  }

  @override
  Widget build(BuildContext context) {
    final filtrati = catalogo.where((l) {
      final okCat = _filtroCategoria == 'Tutte' || l.categoria == _filtroCategoria;
      final okSearch = _search.isEmpty || l.nome.toLowerCase().contains(_search.toLowerCase());
      return okCat && okSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ELECTRIC PRO', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(ditta.nome.isEmpty ? 'Inserisci la tua ditta' : ditta.nome, style: const TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Nuovo / Refresh - azzera tutto', onPressed: _nuovoPreventivo),
          IconButton(icon: const Icon(Icons.delete), tooltip: 'Cancella lavorazioni', onPressed: _cancellaLavorazioni),
          IconButton(icon: const Icon(Icons.business), tooltip: 'Dati ditta', onPressed: () => _mostraDialogDitta()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(controller: _clienteCtrl, decoration: const InputDecoration(labelText: 'Cliente *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Telefono cliente', border: OutlineInputBorder()), keyboardType: TextInputType.phone)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _indirizzoCtrl, decoration: const InputDecoration(labelText: 'Indirizzo lavoro', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('IVA: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ChoiceChip(label: const Text('4%'), selected: _iva == 4, onSelected: (_) => setState(() => _iva = 4)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('10%'), selected: _iva == 10, onSelected: (_) => setState(() => _iva = 10)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('22%'), selected: _iva == 22, onSelected: (_) => setState(() => _iva = 22)),
                  const Spacer(),
                  Text('Prev. $numeroFormattato', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroCategoria,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: ['Tutte', ...AppConfig.categorie].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _filtroCategoria = v ?? 'Tutte'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Cerca lavoro...', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtrati.length,
              itemBuilder: (ctx, i) {
                final l = filtrati[i];
                final esistente = righe.where((r) => r.lavoro.nome == l.nome).toList();
                final qty = esistente.isEmpty ? 0 : esistente.first.qty;
                return Card(
                  child: ListTile(
                    onLongPress: () => _modificaPrezzoBase(l),
                    title: Text(l.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${l.categoria} • ${fmt(l.prezzo)} / ${l.unita}  •  tieni premuto per cambiare prezzo'),
                    trailing: l.categoria == 'Cavi'
                        ? Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => _rimuoviUno(l)),
                                Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _aggiungi(l)),
                              ],
                            ),
                          )
                        : FilledButton(onPressed: () => _aggiungi(l), child: const Text('+ Aggiungi')),
                  ),
                );
              },
            ),
          ),
          if (righe.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(color: Colors.orange.shade50, border: Border(top: BorderSide(color: Colors.orange.shade200))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: righe.length,
                      itemBuilder: (ctx, i) {
                        final r = righe[i];
                        return Row(
                          children: [
                            Expanded(child: Text('${r.lavoro.nome} x${r.qty}', style: const TextStyle(fontSize: 13))),
                            GestureDetector(
                              onTap: () => _modificaPrezzoRiga(r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(6)),
                                child: Text(fmt(r.prezzoPersonalizzato), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(fmt(r.totale), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => setState(() { if (r.qty > 1) r.qty--; else righe.remove(r); })),
                            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => r.qty++)),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Column(
                      children: [
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotale'), Text(fmt(subtotale))]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('IVA ${_iva.toStringAsFixed(0)}%'), Text(fmt(ivaImporto))]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTALE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(fmt(totale), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange))]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Acconto ${_accontoPerc.toStringAsFixed(0)}%'), Text(fmt(acconto))]),
                        const SizedBox(height: 4),
                        const Text(
                          'Preventivo valido 30 giorni. Materiali e manodopera inclusi. Esecuzione a regola d\'arte secondo normative CEI. Acconto alla conferma, saldo a fine lavori.',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(onPressed: _generaPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('VEDI PDF')),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _salvaEInviaWhatsApp,
                                icon: const Icon(Icons.send),
                                label: const Text('INVIA WHATSAPP'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ],
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
