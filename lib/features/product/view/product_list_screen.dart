import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/order/view/place_order_screen.dart';
import 'package:narayan_farms/features/order/view_model/place_order_bloc.dart';
import 'package:narayan_farms/features/product/view_model/product_bloc.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch LoadProducts strictly on Init
    context.read<ProductBloc>().add(const LoadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          return switch (state) {
            ProductInitial() => const SizedBox.shrink(),
            ProductLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductError(message: final msg) => Center(
              child: Text('Error: $msg'),
            ),
            ProductLoaded(products: final products) => _buildList(products),
          };
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products available'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final name = product['name']?.toString() ?? 'Unknown';
        final qty = product['quantity']?.toString() ?? '0';
        final unit = product['unit']?.toString() ?? '';

        return ListTile(
          title: Text(name),
          subtitle: Text('Available: $qty $unit'),
          leading: const Icon(Icons.inventory_2),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider<PlaceOrderBloc>(
                  create: (context) => context.read<PlaceOrderBloc>(),
                  child: PlaceOrderScreen(
                    productId: name, // or product['id'] if you have one
                    productName: name,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
