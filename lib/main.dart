import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const NostalgiaGalleryApp());
}

class NostalgiaGalleryApp extends StatelessWidget {
  const NostalgiaGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'معرض الذكريات',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const GalleryHomeScreen(),
    );
  }
}

class GalleryHomeScreen extends StatefulWidget {
  const GalleryHomeScreen({super.key});

  @override
  State<GalleryHomeScreen> createState() => _GalleryHomeScreenState();
}

class _GalleryHomeScreenState extends State<GalleryHomeScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _fetchOldestPhotos();
  }

  Future<void> _fetchOldestPhotos() async {
    final PermissionStatus status = await Permission.photos.request();
    final bool isStorageGranted = await Permission.storage.request().isGranted;

    if (status.isGranted || isStorageGranted) {
      setState(() => _hasPermission = true);

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        final AssetPathEntity recentAlbum = albums.first;

        final List<AssetEntity> media = await recentAlbum.getAssetListPaged(
          page: 0,
          size: 500,
        );

        media.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

        setState(() {
          _photos = media;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلة إلى الماضي ⏳',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black45,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text("جاري استرجاع أقدم ذكرياتك..."),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: ElevatedButton(
          onPressed: _fetchOldestPhotos,
          child: const Text("يرجى منح الإذن لعرض الصور"),
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(child: Text("لم يتم العثور على صور."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final AssetEntity photo = _photos[index];
        return PhotoTile(asset: photo, index: index);
      },
    );
  }
}

class PhotoTile extends StatelessWidget {
  final AssetEntity asset;
  final int index;

  const PhotoTile({super.key, required this.asset, required this.index});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              ),
              if (index == 0)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'أول صورة',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        }
        return Container(
          color: Colors.white10,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
