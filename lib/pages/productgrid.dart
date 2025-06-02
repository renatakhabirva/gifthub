import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gifthub/services/video_widget.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/services/wishlist_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:gifthub/services/city_service.dart';
enum PriceSortType {
  none,
  ascending,
  descending
}

class RefreshIntent extends Intent {}

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
  List<Map<String, dynamic>> categories = [];

  Map<int, List<Map<String, dynamic>>> categoryParameters = {};
  bool isLoading = true;
  PriceSortType currentSort = PriceSortType.none;
  int? selectedCategory;
  int? selectedParameter;
  int? selectedColor;
  int? userCityId;
  String? userCityName;

  final Map<PriceSortType, String> sortTypeNames = {
    PriceSortType.none: 'Без сортировки',
    PriceSortType.ascending: 'По возрастанию цены',
    PriceSortType.descending: 'По убыванию цены',
  };

  bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserCity();
    fetchCategories();

  }

  final cityService = CityService();

  Future<void> _fetchUserCity() async {
    final result = await cityService.fetchUserCity();
    if (result != null) {
      setState(() {
        userCityId = result['userCityId'];
        userCityName = result['userCityName'];
      });
    }

    fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await supabase
          .from('ProductCategory')
          .select('ProductCategoryID, ProductCategoryName');

      setState(() {
        categories = response;
      });
    } catch (error) {
      print('Ошибка при загрузке категорий: $error');
    }
  }

  Future<void> fetchParametersForCategory(int categoryId) async {
    try {
      final response = await supabase
          .from('Parametr')
          .select('''
            ParametrID,
            ParametrName,
            ParametrProduct!inner(
              ProductID,
              Quantity
            )
          ''')
          .eq('ParametrCategory', categoryId)
          .gt('ParametrProduct.Quantity', 0);

      setState(() {
        categoryParameters[categoryId] = response;
      });
    } catch (error) {
      print('Ошибка при загрузке параметров: $error');
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> filtered = List.from(products);

    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
      product['ProductName']?.toLowerCase()
          .contains(widget.searchQuery.toLowerCase()) ?? false
      ).toList();
    }


    if (selectedCategory != null) {
      filtered = filtered.where((product) =>
      product['ProductCategory'] == selectedCategory
      ).toList();

      if (selectedParameter != null) {
        filtered = filtered.where((product) {
          final parameters = product['ParametrProduct'] as List?;
          return parameters?.any((param) =>
          param['ParametrID'] == selectedParameter &&
              (param['Quantity'] ?? 0) > 0
          ) ?? false;
        }).toList();
      }
    }

    switch (currentSort) {
      case PriceSortType.ascending:
        filtered.sort((a, b) => (a['ProductCost'] as num)
            .compareTo(b['ProductCost'] as num));
        break;
      case PriceSortType.descending:
        filtered.sort((a, b) => (b['ProductCost'] as num)
            .compareTo(a['ProductCost'] as num));
        break;
      case PriceSortType.none:
        break;
    }

    return filtered;
  }



  Future<void> fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await supabase
          .from('Product')
          .select('''
          *,
          ProductSeller:Seller!inner(
            *,
            SellerAddress!inner(
              *,
              Address!inner(*)
            )
          )
        ''')
          .gt('ProductQuantity', 0)
          .eq('ProductSeller.SellerAddress.Address.AddressCity', userCityId ?? 2);

      final enrichedProducts = await Future.wait(response.map((product) async {
        final productId = product['ProductID'];

        final photos = await supabase
            .from('ProductPhoto')
            .select('Photo')
            .eq('ProductID', productId);

        final parameters = await supabase
            .from('ParametrProduct')
            .select('ParametrID, Quantity')
            .eq('ProductID', productId);



        return {
          ...product,
          'ProductPhoto': photos,
          'ParametrProduct': parameters,

        };
      }));

      setState(() {
        products = enrichedProducts;
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

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await fetchProducts();
    await _fetchUserCity();
    setState(() => isLoading = false);
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Фильтры',
                style: TextStyle(
                  color: darkGreen,
                  fontFamily: "segoeui",
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userCityName != null) ...[
                      Text(
                        'Текущий город: $userCityName',
                        style: TextStyle(
                          color: darkGreen,
                          fontFamily: "segoeui",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],


                    Text(
                      'Категория:',
                      style: TextStyle(
                        color: darkGreen,
                        fontFamily: "segoeui",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundBeige,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedCategory,
                        underline: Container(),
                        hint: Text(
                          'Выберите категорию',
                          style: TextStyle(
                            color: darkGreen,
                            fontFamily: "segoeui",
                          ),
                        ),
                        dropdownColor: backgroundBeige,
                        items: [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text(
                              'Все категории',
                              style: TextStyle(
                                color: darkGreen,
                                fontFamily: "segoeui",
                              ),
                            ),
                          ),
                          ...categories.map((category) {
                            return DropdownMenuItem<int>(
                              value: category['ProductCategoryID'],
                              child: Text(
                                category['ProductCategoryName'],
                                style: TextStyle(
                                  color: darkGreen,
                                  fontFamily: "segoeui",
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                            selectedParameter = null;
                            if (value != null) {
                              fetchParametersForCategory(value);
                            }
                          });
                        },
                      ),
                    ),
                    if (selectedCategory != null &&
                        categoryParameters[selectedCategory]?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Параметры категории:',
                        style: TextStyle(
                          color: darkGreen,
                          fontFamily: "segoeui",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundBeige,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedParameter,
                          underline: Container(),
                          hint: Text(
                            'Выберите параметр',
                            style: TextStyle(
                              color: darkGreen,
                              fontFamily: "segoeui",
                            ),
                          ),
                          dropdownColor: backgroundBeige,
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'Все параметры',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontFamily: "segoeui",
                                ),
                              ),
                            ),
                            ...categoryParameters[selectedCategory]!.map((parameter) {
                              return DropdownMenuItem<int>(
                                value: parameter['ParametrID'],
                                child: Text(
                                  '${parameter['ParametrName']}',
                                  style: TextStyle(
                                    color: darkGreen,
                                    fontFamily: "segoeui",
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedParameter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                          selectedParameter = null;
                          selectedColor = null;
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkGreen,
                      ),
                      child: Text(
                        'Сбросить',
                        style: TextStyle(
                            fontFamily: "segoeui",
                            fontSize: 16
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Применить',
                        style: TextStyle(
                            fontFamily: "segoeui",
                            fontSize: 16
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: darkGreen.withOpacity(0.5)),
        SizedBox(height: 16),
        Text(
          'Товары не найдены',
          style: TextStyle(
            color: darkGreen,
            fontFamily: "segoeui",
            fontSize: 18,
          ),
        ),
        if (selectedCategory != null || selectedColor != null)
          TextButton(
            onPressed: () {
              setState(() {
                selectedCategory = null;
                selectedParameter = null;
                selectedColor = null;
              });
            },
            child: Text('Сбросить фильтры'),
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
        ? product['ProductPhoto'][0]['Photo']
        : 'https://picsum.photos/200/300';

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/product/${product['ProductID']}',
        arguments: product,
      ),
      child: Card(
        elevation: 0,
        color: backgroundBeige,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: buildMediaWidget(imageUrl),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        product['ProductName'] ?? 'Без названия',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          fontFamily: "segoeui",
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${product['ProductCost']} ₽',
                        style: TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                          fontFamily: "segoeui",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 5,
              child: _buildWishlistButton(product['ProductID']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistButton(int productId) {
    return StatefulBuilder(
      builder: (context, setStateIcon) {
        final isInWishlist = ValueNotifier<bool>(false);
        checkInWishlist(productId).then((value) => isInWishlist.value = value);

        return ValueListenableBuilder<bool>(
          valueListenable: isInWishlist,
          builder: (context, value, _) {
            return IconButton(
              icon: Icon(
                value ? Icons.favorite : Icons.favorite_border,
                color: value ? wishListIcon : null,
              ),
              onPressed: () => toggleWishlistService(
                context: context,
                productId: productId,
                isInWishlist: isInWishlist,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: backgroundBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.filter_list, color: darkGreen),
                      if (selectedCategory != null || selectedColor != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: wishListIcon,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: showFilterDialog,
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundBeige,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<PriceSortType>(
                      value: currentSort,
                      underline: Container(),
                      style: TextStyle(
                        color: darkGreen,
                        fontFamily: "segoeui",
                      ),
                      dropdownColor: backgroundBeige,
                      items: PriceSortType.values.map((PriceSortType type) {
                        return DropdownMenuItem<PriceSortType>(
                          value: type,
                          child: Text(
                            sortTypeNames[type]!,
                            style: TextStyle(color: darkGreen),
                          ),
                        );
                      }).toList(),
                      onChanged: (PriceSortType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            currentSort = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (userCityName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: darkGreen),
                SizedBox(width: 4),
                Text(
                  maxLines: 2,
                  'Товары доступные в городе $userCityName',
                  style: TextStyle(
                    color: darkGreen,
                    fontFamily: "segoeui",
                    fontSize: 14,

                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? Center(child: _buildEmptyState())
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
                padding: EdgeInsets.only(bottom: 90, top: 0),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(filteredProducts[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.f5): RefreshIntent(),
        },
        child: Actions(
          actions: {
            RefreshIntent: CallbackAction(onInvoke: (_) => _refreshData()),
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text('Каталог товаров'),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Обновить',
                  onPressed: _refreshData,
                ),
              ],
            ),
            body: Scrollbar(
              child: _buildContent(),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await _refreshData();
          },
          child: _buildContent(),
        ),
      );
    }
  }
}