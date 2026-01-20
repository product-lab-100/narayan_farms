import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/order/view_model/place_order_bloc.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const PlaceOrderScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: BlocConsumer<PlaceOrderBloc, PlaceOrderState>(
        listener: (context, state) {
          if (state is PlaceOrderSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            // Optionally pop or navigate
          }
        },
        builder: (context, state) {
          if (state is PlaceOrderSubmitting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: ${widget.productName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                if (state is PlaceOrderError) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final qty = int.tryParse(_quantityController.text) ?? 1;
                      context.read<PlaceOrderBloc>().add(
                        PlaceOrderPressed(
                          productId: widget.productId,
                          quantity: qty,
                        ),
                      );
                    },
                    child: const Text('Place Order'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
