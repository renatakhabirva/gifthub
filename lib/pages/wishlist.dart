import 'package:flutter/material.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/services/wishlist_service.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/services/video_widget.dart';
import 'package:gifthub/themes/colors.dart';

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
    fetchWishlistProducts();
    subscribeToWishlistUpdates();
  }
  @override
  void dispose() {
    supabase.channel('wishlist-updates').unsubscribe();
    super.dispose();
  }
  void subscribeToWishlistUpdates() {
    supabase.channel('wishlist-updates')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'WishList',
      callback: (payload, [ref]) {

        fetchWishlistProducts();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'WishList',
      callback: (payload, [ref]) {

        fetchWishlistProducts();
      },
    )
        .subscribe();
  }


  Future<void> fetchWishlistProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('WishList')
          .select('Product, Product!inner(*, ProductPhoto(*))')
          .eq('Client', user.id);

      final List<Map<String, dynamic>> products = response
          .map<Map<String, dynamic>>((entry) => entry['Product'] as Map<String, dynamic>)
          .toList();

      setState(() {
        wishlistProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> refreshWishlist() async {
    try {
      setState(() => isLoading = true);
      await fetchWishlistProducts();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleWishlist({
    required BuildContext context,
    required int productId,
  }) async {
    final notifier = ValueNotifier<bool>(isInWishlist(productId));


    await toggleWishlistService(
      context: context,
      productId: productId,
      isInWishlist: notifier,
    );

    // обновление локального списка
    if (notifier.value) {
      final response = await supabase
          .from('Product')
          .select('*, ProductPhoto(*)')
          .eq('ProductID', productId)
          .single();

      setState(() {
        wishlistProducts.add(response);
      });
    } else {
      setState(() {
        wishlistProducts.removeWhere((product) => product['ProductID'] == productId);
      });
    }
  }

  bool isInWishlist(int productId) {
    return wishlistProducts.any((product) => product['ProductID'] == productId);
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
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported),
    );
  }

  Widget buildWishlistContent() {


      return isLoading
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
            padding: EdgeInsets.only(left: 5, right: 5, bottom: 90, top: 0),
            itemCount: wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = wishlistProducts[index];
              final List<dynamic>? photos = product['ProductPhoto'];
              final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
                  ? product['ProductPhoto'][0]['Photo']
                  : 'https://picsum.photos/200/300';
              final productId = product['ProductID'] as int;
              final isFavorite = isInWishlist(productId);

              return InkWell(
                key: ValueKey(product['ProductID']),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/product/${product['ProductID']}',
                    arguments: product,
                  );
                },
                child: Card(
                  elevation: 0,
                  color: backgroundBeige,
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
                                    product['ProductName'] ?? 'Без названия',
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
                        child: IconButton(
                          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                          color: wishListIcon,
                          onPressed: () async {
                            await toggleWishlist(
                              context: context,
                              productId: productId,
                            );
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

    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      supabase.auth.signOut();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.favorite_outline),
          onPressed: null,
        ),
        title: Text("Избранное",),

      ),
      body: user == null
          ? Center(child: Text('Вы не авторизованы'))
          : RefreshIndicator(
        onRefresh: refreshWishlist, //  для мобильных устройств
        child: buildWishlistContent(),
      ),
    );
  }
}