import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// COMMIT 2: Integración de un Banner adaptable anclado (AdMob).
// Se usa el ID de unidad de anuncios DE DEMOSTRACIÓN de Google,
// que siempre muestra anuncios de prueba y es seguro para desarrollo.

const String bannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1) Inicializar el SDK de Google Mobile Ads una sola vez al arrancar.
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Banner AdMob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se carga aquí porque necesitamos el ancho de pantalla (MediaQuery).
    if (_bannerAd == null) _loadAd();
  }

  Future<void> _loadAd() async {
    // 2) Obtener el tamaño adaptable según el ancho y la orientación actual.
    final width = MediaQuery.of(context).size.width.truncate();
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null) {
      debugPrint('No se pudo obtener el tamaño del banner adaptable.');
      return;
    }

    // 3) Crear y cargar el banner.
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner cargado correctamente.');
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Error al cargar el banner: $error');
          ad.dispose();
        },
        onAdClicked: (ad) => debugPrint('Banner clicado.'),
      ),
    );
    await _bannerAd!.load();
  }

  @override
  void dispose() {
    // 4) Liberar el anuncio al salir de la pantalla.
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Banner AdMob'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Elemento ${index + 1}'),
          subtitle: const Text('Contenido de ejemplo de la aplicación'),
        ),
      ),
      // 5) El banner queda "anclado" en la parte inferior de la pantalla.
      bottomNavigationBar: _isLoaded && _bannerAd != null
          ? SafeArea(
              child: Container(
                color: Colors.white, // fondo opaco (política de AdMob)
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }
}
