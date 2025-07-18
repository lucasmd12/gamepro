

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/services/cache_service.dart';

class CustomCacheManager extends CacheManager {
  static const key = "customCacheKey";

  static final CustomCacheManager _instance = CustomCacheManager._();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._() : super(Config(key));
}

class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final String? imageId;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.imageId,
    this.width,
    this.height,
    this.fit,
  });

  @override
  _CachedImageWidgetState createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      cacheManager: CustomCacheManager(),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      // Adicione o gerenciamento de cache manual aqui
      // para garantir que as imagens sejam salvas e recuperadas corretamente.
      // Isso pode ser feito usando o CacheService.
      // Exemplo:
      // imageBuilder: (context, imageProvider) {
      //   if (widget.imageId != null) {
      //     CacheService.instance.setImageUrl(widget.imageId!, widget.imageUrl);
      //   }
      //   return Image(image: imageProvider);
      // },
      // progressIndicatorBuilder: (context, url, downloadProgress) =>
      //     CircularProgressIndicator(value: downloadProgress.progress),
    );
  }

  @override
  void initState() {
    super.initState();
    _cacheImage();
  }

  Future<void> _cacheImage() async {
    if (widget.imageId != null) {
      final cachedUrl = await CacheService.instance.getImageUrl(widget.imageId!); // Corrigido
      if (cachedUrl == null || cachedUrl != widget.imageUrl) {
        await CacheService.instance.setImageUrl(widget.imageId!, widget.imageUrl); // Corrigido
      }
    }
  }
}


