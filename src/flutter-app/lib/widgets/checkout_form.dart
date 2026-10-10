import 'package:flutter/material.dart';

import '../models/checkout.dart';
import '../theme/app_theme.dart';

/// Pre-filled with the same placeholder values as the react-native-app's
/// `CheckoutForm.tsx` (itself ported from the web frontend's checkout form).
class CheckoutFormData {
  String email;
  String streetAddress;
  String city;
  String state;
  String country;
  String zipCode;
  String creditCardNumber;
  int creditCardCvv;
  int creditCardExpirationYear;
  int creditCardExpirationMonth;

  CheckoutFormData({
    this.email = 'someone@example.com',
    this.streetAddress = '1600 Amphitheatre Parkway',
    this.city = 'Mountain View',
    this.state = 'CA',
    this.country = 'United States',
    this.zipCode = '94043',
    this.creditCardNumber = '4432-8015-6152-0454',
    this.creditCardCvv = 672,
    this.creditCardExpirationYear = 2030,
    this.creditCardExpirationMonth = 1,
  });

  Address toAddress() => Address(
        streetAddress: streetAddress,
        city: city,
        state: state,
        country: country,
        zipCode: zipCode,
      );

  CreditCardInfo toCreditCard() => CreditCardInfo(
        creditCardNumber: creditCardNumber,
        creditCardCvv: creditCardCvv,
        creditCardExpirationYear: creditCardExpirationYear,
        creditCardExpirationMonth: creditCardExpirationMonth,
      );
}

class CheckoutForm extends StatefulWidget {
  final void Function(CheckoutFormData data) onSubmit;

  const CheckoutForm({super.key, required this.onSubmit});

  @override
  State<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<CheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = CheckoutFormData();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'E-mail Address',
            initialValue: _data.email,
            onSaved: (v) => _data.email = v!,
          ),
          _field(
            'Street Address',
            initialValue: _data.streetAddress,
            onSaved: (v) => _data.streetAddress = v!,
          ),
          _field(
            'Zip Code',
            initialValue: _data.zipCode,
            onSaved: (v) => _data.zipCode = v!,
          ),
          _field(
            'City',
            initialValue: _data.city,
            onSaved: (v) => _data.city = v!,
          ),
          _field(
            'State',
            initialValue: _data.state,
            onSaved: (v) => _data.state = v!,
          ),
          _field(
            'Country',
            initialValue: _data.country,
            onSaved: (v) => _data.country = v!,
          ),
          _field(
            'Credit Card Number',
            initialValue: _data.creditCardNumber,
            keyboardType: TextInputType.number,
            onSaved: (v) => _data.creditCardNumber = v!,
          ),
          _field(
            'Expiration Month',
            initialValue: _data.creditCardExpirationMonth.toString(),
            keyboardType: TextInputType.number,
            onSaved: (v) => _data.creditCardExpirationMonth = int.parse(v!),
          ),
          _field(
            'Expiration Year',
            initialValue: _data.creditCardExpirationYear.toString(),
            keyboardType: TextInputType.number,
            onSaved: (v) => _data.creditCardExpirationYear = int.parse(v!),
          ),
          _field(
            'CVV',
            initialValue: _data.creditCardCvv.toString(),
            keyboardType: TextInputType.number,
            onSaved: (v) => _data.creditCardCvv = int.parse(v!),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.light.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _submit,
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      return;
    }
    form.save();
    widget.onSubmit(_data);
  }

  Widget _field(
    String label, {
    required String initialValue,
    required void Function(String?) onSaved,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        onSaved: onSaved,
      ),
    );
  }
}
