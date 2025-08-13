import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';

class Vics extends StatefulWidget {
  const Vics({super.key});

  @override
  State<Vics> createState() => _VicsState();
}

class _VicsState extends State<Vics> {
  Future<void> _loadUser() async {
    final userP = Provider.of<UserProvider>(context, listen: false);
    final agencyId =
        userP.user?.agencyId; // Assuming user has an agencyId property
    if (agencyId != null) {
      await _loadProducts(agencyId);
    }
  }

  Future<void> _loadProducts(String agencyId) async {
    final productProvider = Provider.of<AgencyProvider>(context, listen: false);
    await productProvider.fetchAgencyProducts(agencyId);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
    super.initState();
  }

  final List<String> items = [
    'All',
    'Users',
    'Products'
  ];

  String? selectedValue;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enable')),
      body: Consumer<AgencyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          } else if (provider.products.isEmpty) {
            return Center(child: Text('No products available.'));
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: Text(
                          'All',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        items: items
                            .map((String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ))
                            .toList(),
                        value: selectedValue,
                        onChanged: (String? value) {
                          setState(() {
                            selectedValue = value;
                          });
                        },
                        buttonStyleData:  ButtonStyleData(
                          decoration: BoxDecoration(
                            color: Color(0xff383232),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Color(0xff383232)
                            )
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 35,
                          width: 80
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1
                      ),
                      shrinkWrap: true,
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        final hasImage = product.mediaPhotos != null &&
                            product.mediaPhotos!.isNotEmpty &&
                            product.mediaPhotos![0].imageUrl != null;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1,color:Colors.grey[300]!)
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image:hasImage? NetworkImage(
                                          product.mediaPhotos![0].signedUrl!
                                      ):AssetImage("/assets/imgs/noimg.png"),
                                      fit: BoxFit.cover
                                    )
                                  ),
                                )
                              ),
                              Expanded(
                                flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding:EdgeInsets.all(10),
                                          width: 30,
                                          decoration: BoxDecoration(
                                              color: Color(0xff292525),
                                              borderRadius: BorderRadius.circular(5)
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset('assets/icons/chat.svg'),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(product.name),
                                        SizedBox(height: 10),
                                        Text(product.category),
                                      ],
                                    ),
                                  )
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
