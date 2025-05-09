import 'package:flutter/material.dart';
import 'package:gifthub/pages/video_widget.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/pages/wishlist_service.dart';

class ResponsiveGrid extends StatefulWidget {
  final String searchQuery;
  final Function(Map<String, dynamic>)? onProductTap;

  const ResponsiveGrid({
    super.key,
    required this.searchQuery,
    this.onProductTap,
  });

  @override
  State<ResponsiveGrid> createState() => _ResponsiveGridState();
}

class _ResponsiveGridState extends State<ResponsiveGrid> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  

  List<Map<String, dynamic>> get filteredProducts {
    if (widget.searchQuery.isEmpty) return products;

    return products.where((product) =>
    product['ProductName']?.toLowerCase()
        .contains(widget.searchQuery.toLowerCase()) ?? false
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();

  }

  Future<void> fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await supabase
          .from('Product')
          .select('''
            ProductID,
            ProductName,
            ProductCost,
            ProductPhoto(Photo)
          ''');

      setState(() {
        products = response;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Ошибка при загрузке продуктов: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке продуктов: $error')),
      );
    }
  }

  bool isVideoUrl(String url) {
    final extensions = ['.mp4', '.mov', '.avi', '.wmv'];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  Widget buildMediaWidget(String url) {
    if (isVideoUrl(url)) {
      return VideoPlayerScreen(
        videoUrl: url,
        isMuted: true,
      );
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredProducts.isEmpty
          ? Center(child: Text('Товары не найдены'))
          : LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 150)
              .floor()
              .clamp(2, 6);
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            padding: EdgeInsets.only(bottom: 90, top: 0),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
                  ? product['ProductPhoto'][0]['Photo']
                  : 'https://picsum.photos/200/300';

              return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Card(

                    elevation: 0,
                    color: backgroundBeige,
                    borderOnForeground: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(

                              flex: 4,
                              child: ClipRRect(

                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                child: buildMediaWidget(imageUrl),

                              ),

                            ),

                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Flexible(
                                    child: Text(
                                      product['ProductName'] ??
                                          'Без названия',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                        fontFamily: "segoeui",
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${product['ProductCost']} ₽',
                                      style: TextStyle(
                                        color: darkGreen,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "segoeui",
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 5,
                          child: StatefulBuilder(
                            builder: (context, setStateIcon) {
                              final isInWishlist = ValueNotifier<bool>(false);
                              final productId = product['ProductID'];
                              //  есть ли в избранном
                              checkInWishlist(productId).then((value) {
                                isInWishlist.value = value;
                              });


                              return ValueListenableBuilder<bool>(
                                valueListenable: isInWishlist,
                                builder: (context, value, _) {
                                  return IconButton(
                                    icon: Icon(
                                      value ? Icons.favorite : Icons.favorite_border,
                                      color: value ? wishListIcon : null,
                                    ),
                                    color: wishListIcon,
                                    onPressed: () {
                                      toggleWishlistService(
                                        context: context,
                                        productId: productId,
                                        isInWishlist: isInWishlist,
                                      );

                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      ],
                    ),
                  ));
            },
          );
        },
      ),
    );
  }
}