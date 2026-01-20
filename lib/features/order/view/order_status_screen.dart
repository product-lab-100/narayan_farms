import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/order/view_model/order_status_bloc.dart';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event to start tracking
    context.read<OrderStatusBloc>().add(OrderStatusStarted(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: Center(
        child: BlocBuilder<OrderStatusBloc, OrderStatusState>(
          builder: (context, state) {
            if (state is OrderStatusInitial || state is OrderStatusLoading) {
              return const CircularProgressIndicator();
            }

            if (state is OrderStatusCreated) {
              return const Text(
                'State: Created',
                style: TextStyle(fontSize: 24),
              );
            }

            if (state is OrderStatusAssigned) {
              return const Text(
                'State: Assigned',
                style: TextStyle(fontSize: 24, color: Colors.blue),
              );
            }

            if (state is OrderStatusDelivered) {
              return const Text(
                'State: Delivered',
                style: TextStyle(fontSize: 24, color: Colors.green),
              );
            }

            if (state is OrderStatusFailed) {
              return Text(
                'Error: ${state.message}',
                style: const TextStyle(fontSize: 24, color: Colors.red),
              );
            }

            return const Text('Unknown State');
          },
        ),
      ),
    );
  }
}
