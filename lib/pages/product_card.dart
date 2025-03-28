import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gifthub/pages/video_widget.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/productgrid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailScreenState extends StatelessWidget {
  final Map<String, dynamic> product;
  final dynamic Function(bool)? onBack;

  const ProductDetailScreenState({
    Key? key,

    required this.product,
    this.onBack,
  }) : super(key: key);

  Future<String> fetchProductDescription(int productId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('Product')
          .select('ProductDescription')
          .eq('ProductID', productId)
          .single();

      return response['ProductDescription'] ?? 'Описание отсутствует';
    } catch (error) {
      print('Ошибка при получении описания: $error');
      return 'Описание отсутствует';
    }
  }

  Widget buildMediaWidget(String url) {
    if (isVideoUrl(url)) {
      return VideoPlayerScreen(videoUrl: url);
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported),
    );
  }

  bool isVideoUrl(String url) {
    final extensions = ['.mp4', '.mov', '.avi', '.wmv'];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  Future<String> formatProductDescription(int productId) async {
    if (product['ProductDescription'] != null &&
        product['ProductDescription']?.isNotEmpty ?? false) {
      return product['ProductDescription'] ?? 'Описание отсутствует';
    }
    return await fetchProductDescription(productId);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> mediaUrls = product['ProductPhoto']?.isNotEmpty ?? false
        ? List<String>.from(product['ProductPhoto'].map((e) => e['Photo']))
        : ['https://via.placeholder.com/150'];

    return WillPopScope(
      onWillPop: () async {
        onBack?.call(true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(product['ProductName']),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              onBack?.call(true);
            },
          ),
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'segoeui',
              color: darkGreen,
              fontSize: 24
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLargeScreen)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1,
                        enableInfiniteScroll: false,
                        autoPlay: false,
                      ),
                      items: mediaUrls.map((url) {
                        return Builder(
                          builder: (BuildContext context) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: buildMediaWidget(url),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLargeScreen)
                        Expanded(
                          flex: 2,
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: constraints.maxHeight * 0.8,
                              viewportFraction: 1,
                              enableInfiniteScroll: false,
                              autoPlay: false,
                            ),
                            items: mediaUrls.map((url) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: buildMediaWidget(url),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      Expanded(
                        flex: isLargeScreen ? 3 : 1,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, top: 5),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product['ProductCost']} ₽',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: darkGreen,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Описание продукта:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              FutureBuilder<String>(
                                future: formatProductDescription(product['ProductID']),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(
                                      snapshot.data!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ].where((child) => child != null).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}