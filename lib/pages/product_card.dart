import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gifthub/pages/video_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/pages/wishlist_service.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/add_to_cart.dart';
import 'package:gifthub/pages/quantity_product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(bool)? onBack;

  const ProductDetailScreen({
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


  Widget buildMediaWidget(BuildContext context, String url, List<String> mediaUrls, int initialIndex) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: backgroundBeige.withOpacity(0.5),
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                Center(
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView.builder(
                      itemCount: mediaUrls.length,
                      controller: PageController(initialPage: initialIndex),
                      itemBuilder: (context, index) {
                        final mediaUrl = mediaUrls[index];
                        return isVideoUrl(mediaUrl)
                            ? ClipRRect(
                          child: VideoPlayerScreen(videoUrl: mediaUrl, isFullscreen: true),
                        )
                            : InteractiveViewer(
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported, color: darkGreen),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  child: IconButton(
                    icon: Icon(Icons.close, color: darkGreen, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: isVideoUrl(url)
          ? ClipRRect(
        child: VideoPlayerScreen(videoUrl: url, isFullscreen: false),
      )
          : ClipRRect(
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.image_not_supported, color: darkGreen),
        ),
      ),
    );
  }

  //  является ли URL видео
  bool isVideoUrl(String url) {
    final extensions = ['.mp4', '.mov', '.avi', '.wmv'];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  // получение параметров товара
  Future<List<Map<String, dynamic>>> fetchProductParameters(int productId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('ParametrProduct')
          .select('Parametr(ParametrName)')
          .eq('ProductID', productId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Ошибка при получении параметров: $e');
      return [];
    }
  }
  Future<bool> hasParameters(int productId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('ParametrProduct')
          .select('Parametr(ParametrName)')
          .eq('ProductID', productId);
      return response.isNotEmpty; //  true, если параметры есть
    } catch (e) {
      print('Ошибка при проверке наличия параметров: $e');
      return false;
    }
  }


  Future<String> formatProductDescription(int productId) async {
    if (product['ProductDescription'] != null && product['ProductDescription'].isNotEmpty) {
      return product['ProductDescription'] ?? 'Описание отсутствует';
    }
    return await fetchProductDescription(productId);
  }


  @override
  Widget build(BuildContext context) {

    final List<String> mediaUrls = product['ProductPhoto']?.isNotEmpty ?? false
        ? List<String>.from(product['ProductPhoto'].map((e) => e['Photo']))
        : ['https://picsum.photos/200/300'];


    final isInWishlist = ValueNotifier<bool>(false);
    checkInWishlist(product['ProductID']).then((value) {
      isInWishlist.value = value;
    });


    final selectedParameter = ValueNotifier<String?>(null);

    return WillPopScope(
      onWillPop: () async {
        onBack?.call(true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(product['ProductName']),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: isInWishlist,
              builder: (context, isFavorite, child) {
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? wishListIcon : null,
                  ),
                  onPressed: () {
                    toggleWishlistService(
                      context: context,
                      productId: product['ProductID'],
                      isInWishlist: isInWishlist,
                    );
                  },
                );
              },
            ),
          ],
          titleTextStyle: TextStyle(
            fontFamily: 'segoeui',
            color: darkGreen,
            fontSize: 24,
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (!isLargeScreen)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 350,
                        viewportFraction: 1,
                        enableInfiniteScroll: false,
                        autoPlay: false,
                      ),
                      items: mediaUrls.map((url) {
                        return Builder(
                          builder: (BuildContext context) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: buildMediaWidget(context, url, mediaUrls, mediaUrls.indexOf(url)),
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
                                    child: buildMediaWidget(context, url, mediaUrls, mediaUrls.indexOf(url)),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),

                      Expanded(
                        flex: isLargeScreen ? 3 : 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Цена товара
                              Text(
                                '${product['ProductCost']} ₽',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Параметры товара
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: fetchProductParameters(product['ProductID']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }

                                  final parameters = snapshot.data!;
                                  if (parameters.isEmpty) return const SizedBox.shrink();

                                  return ValueListenableBuilder<String?>(
                                    valueListenable: selectedParameter,
                                    builder: (context, selected, _) {
                                      return Wrap(
                                        spacing: 8,
                                        children: parameters.map((param) {
                                          final name = param['Parametr']['ParametrName'];
                                          final isSelected = selected == name;

                                          return FutureBuilder<int?>(
                                            future: fetchParametrId(name).then((id) => id != null ? fetchParametrQuantity(product['ProductID'], id) : null),
                                            builder: (context, quantitySnapshot) {
                                              final quantity = quantitySnapshot.data ?? 0;

                                              bool isAvailable = quantity > 0;

                                              return ChoiceChip(
                                                label: Text(name),
                                                selected: isSelected,
                                                showCheckmark: false,
                                                onSelected: isAvailable ? (_) => selectedParameter.value = name : null,
                                                selectedColor: isAvailable ? darkGreen : Colors.grey,
                                                disabledColor: Colors.grey[300],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5),
                                                  side: BorderSide(
                                                    color: !isAvailable ? lightGrey : isSelected ? darkGreen : Colors.grey,
                                                    width: 2,
                                                    style: !isAvailable ? BorderStyle.solid : BorderStyle.none,
                                                    strokeAlign: BorderSide.strokeAlignOutside,
                                                  ),
                                                ),
                                                labelStyle: TextStyle(
                                                  color: isSelected && isAvailable ? Colors.white : darkGreen,
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  FutureBuilder<int?>(
                                    future: selectedParameter.value != null
                                        ? fetchParametrId(selectedParameter.value!).then((id) =>
                                        fetchParametrQuantity(product['ProductID'], id!))
                                        : fetchAvailableQuantity(product['ProductID']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      final quantity = snapshot.data ?? 0;

                                      if (quantity <= 0) {
                                        return Text(
                                          'Нет в наличии',
                                          style: TextStyle(
                                            color: wishListIcon ,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        );
                                      }

                                      return ElevatedButton(
                                        onPressed: () async {
                                          final selectedParamName = selectedParameter.value;
                                          final hasParams = await hasParameters(product['ProductID']);

                                          if (hasParams && selectedParamName == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Выберите параметры товара перед добавлением в корзину'),
                                              ),
                                            );
                                            return;
                                          }

                                          final parametrId = selectedParamName == null
                                              ? null
                                              : await fetchParametrId(selectedParamName);

                                          addToCart(context, product['ProductID'], parametrId);
                                        },
                                        child: const Text('Добавить в корзину'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Описание продукта:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'segoeui',
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<String>(
                                future: formatProductDescription(product['ProductID']),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(
                                      snapshot.data!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: darkGrey,
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}