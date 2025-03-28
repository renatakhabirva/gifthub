import 'package:flutter/material.dart';
import 'package:gifthub/pages/video_widget.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistGrid extends StatefulWidget {
  final Function(Map<String, dynamic>)? onProductTap;

  const WishlistGrid({
    super.key,
    this.onProductTap,
  });

  @override
  State<WishlistGrid> createState() => _WishlistGridState();
}

class _WishlistGridState extends State<WishlistGrid> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> wishlistProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        wishlistProducts = [];
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final response = await supabase
          .from('WishList')
          .select('Product, Product(ProductID, ProductName, ProductCost, ProductPhoto(Photo))')
          .eq('Client', user.id);

      // Преобразуем данные правильно
      final List<Map<String, dynamic>> fetchedProducts = response.map<Map<String, dynamic>>((item) => {
        'ProductID': item['ProductID'],
        'ProductName': item['Product']['ProductName'],
        'ProductCost': item['Product']['ProductCost'],
        'ProductPhoto': item['Product']['ProductPhoto']
      }).toList();

      setState(() {
        wishlistProducts = fetchedProducts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Ошибка при загрузке Wishlist: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке списка желаемого: $error')),
      );
    }
  }


  bool isVideoUrl(String url) {
    final extensions = ['.mp4', '.mov', '.avi', '.wmv'];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  Widget buildMediaWidget(String? url) {
    if (url == null) {
      return Icon(Icons.image_not_supported);
    }
    if (isVideoUrl(url)) {
      return VideoPlayerScreen(videoUrl: url);
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    // Если пользователь удалён, разлогиниваем его
    if (user == null) {
      supabase.auth.signOut(); // Выход из аккаунта
    }

    return Scaffold(
      body: user == null
          ? Center(child: Text('Вы не авторизованы'))
          : isLoading
          ? Center(child: CircularProgressIndicator())
          : wishlistProducts.isEmpty
          ? Center(child: Text('Ваш список желаемого пуст'))
          : LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 6);
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            padding: EdgeInsets.all(8),
            itemCount: wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = wishlistProducts[index];
              final List<dynamic>? photos = product['ProductPhoto'];

              final imageUrl = (photos != null && photos.isNotEmpty)
                  ? photos[0]['Photo'] as String?
                  : 'https://via.placeholder.com/150';

              return InkWell(
                onTap: () {
                  widget.onProductTap?.call(product);
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
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              child: buildMediaWidget(imageUrl),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Flexible(
                                  child: Text(
                                    product['ProductName'] ?? 'Без названия',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                      fontFamily: "segoeui",
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
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
                        child: IconButton(
                          icon: Icon(Icons.favorite),
                          color: darkGreen,
                          onPressed: () {
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}