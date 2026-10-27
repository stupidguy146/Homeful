import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/household_item.dart';
import '../models/api_error.dart';
import '../services/api_service.dart';
import '../services/product_lookup_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/app_strings.dart';
import '../i18n/locale_scope.dart';
import '../validators/item_form_validators.dart';

/// Add or edit a household item (form follows the homeful mockup).
class AddEditItemScreen extends StatefulWidget {
  final HouseholdItem? existing;
  const AddEditItemScreen({super.key, this.existing});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _size;
  late final TextEditingController _unit;
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _store;
  late final TextEditingController _buyer;

  ApiService? _api;
  ItemCategory _category = ItemCategory.other;
  String? _unitLabel;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  String? _image;
  bool _recurring = false;
  bool _saving = false;
  bool _lookingUpBarcode = false;
  String? _scannedBarcode;
  final _productLookup = ProductLookupService();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _size = TextEditingController(text: e?.size ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _qty = TextEditingController(text: '${e?.quantity ?? 1}');
    _unitLabel = e?.unitLabel?.trim();
    if (_unitLabel?.isEmpty ?? false) _unitLabel = null;
    _price = TextEditingController(text: '${e?.price ?? 0}');
    _store = TextEditingController(text: e?.store ?? '');
    _buyer = TextEditingController(text: e?.buyer ?? '');
    _category = e?.category ?? ItemCategory.other;
    _image = e?.imageBase64;
    _recurring = e?.notifyRecurring ?? false;
    if (e?.purchaseDate != null) _purchaseDate = DateTime.tryParse(e!.purchaseDate!);
    if (e?.expiryDate != null) _expiryDate = DateTime.tryParse(e!.expiryDate!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiService(auth: AuthScope.of(context));
  }

  @override
  void dispose() {
    _productLookup.close();
    for (final c in [
      _name, _size, _unit, _qty, _price, _store, _buyer
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() => _image = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    setState(() {
      _scannedBarcode = barcode;
      _lookingUpBarcode = true;
    });
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final product = await _productLookup.lookup(barcode);
      if (!mounted) return;
      if (product == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(s.barcodeLookupNotFound)),
        );
        return;
      }
      setState(() {
        _name.text = product.name;
        if (product.size != null) _size.text = product.size!;
        if (product.unit != null) _unit.text = product.unit!;
        if (product.category != null) _category = product.category!;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(s.barcodeLookupSuccess)),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(s.errorWith(e))));
      }
    } finally {
      if (mounted) setState(() => _lookingUpBarcode = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'category': categoryToString(_category),
      'size': _size.text.trim().isEmpty ? null : _size.text.trim(),
      'unit': _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      'quantity': int.tryParse(_qty.text) ?? 1,
      'unitLabel': _unitLabel,
      'price': double.tryParse(_price.text) ?? 0,
      'store': _store.text.trim().isEmpty ? null : _store.text.trim(),
      'buyer': _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
      'purchaseDate': _purchaseDate?.toIso8601String().substring(0, 10),
      'expiryDate': _expiryDate?.toIso8601String().substring(0, 10),
      'imageBase64': _image,
      'notifyRecurring': _recurring,
    };
    final messenger = ScaffoldMessenger.of(context);
    final s = context.strings;
    final dataRefresh = DataScope.of(context);
    try {
      if (_isEdit) {
        await _api!.updateItem(widget.existing!.itemId, body);
      } else {
        await _api!.createItem(body);
      }
      dataRefresh.bump();
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(s.itemSaved)));
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.errorForCode(e.code, fallback: e.message))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorWith(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final img = _decode(_image);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              subtitle: s.itemsTitle,
              title: _isEdit ? s.editItemTitle : s.addItemTitle,
              leading: _Back(onTap: () => Navigator.pop(context)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.brand100,
                            borderRadius: AppRadius.rLg,
                            image: img != null
                                ? DecorationImage(
                                    image: MemoryImage(img), fit: BoxFit.cover)
                                : null,
                          ),
                          child: img == null
                              ? const Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.brand500, size: 30)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.itemName,
                        helperText: _scannedBarcode == null
                            ? null
                            : s.scannedBarcode(_scannedBarcode!),
                        suffixIcon: _lookingUpBarcode
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                tooltip: s.scanBarcode,
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                              ),
                      ),
                      validator: (v) => ItemFormValidators.requiredName(
                        v,
                        requiredMessage: s.itemName,
                        invalidMessage: s.lettersNumbersSpacesOnly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<ItemCategory>(
                      initialValue: _category,
                      decoration: InputDecoration(labelText: s.categoryLabel),
                      dropdownColor: Theme.of(context).cardTheme.color,
                      borderRadius: AppRadius.rMd,
                      items: ItemCategory.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child:
                                    Text(s.categoryName(categoryToString(c))),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _size,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) =>
                                    ItemFormValidators.decimalInput
                                            .hasMatch(newValue.text)
                                        ? newValue
                                        : oldValue,
                              ),
                            ],
                            decoration: InputDecoration(labelText: s.sizeLabel),
                            validator: (v) =>
                                ItemFormValidators.optionalDecimal(
                              v,
                              s.decimalNumberOnly,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _unit,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  ItemFormValidators.letterCharacters),
                            ],
                            decoration:
                                InputDecoration(labelText: s.unitFieldLabel),
                            validator: (v) => ItemFormValidators.optionalLetters(
                              v,
                              s.lettersOnly,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(labelText: s.quantity),
                            validator: (v) =>
                                ItemFormValidators.positiveInteger(
                              v,
                              requiredMessage: s.quantity,
                              invalidMessage: s.positiveIntegerOnly,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _unitLabel ?? '',
                            decoration: InputDecoration(
                              labelText: s.unitLabelField,
                            ),
                            dropdownColor: Theme.of(context).cardTheme.color,
                            borderRadius: AppRadius.rMd,
                            items: [
                              DropdownMenuItem(
                                value: '',
                                child: Text(s.noUnitCount),
                              ),
                              for (final label in _unitCountOptions(s))
                                DropdownMenuItem(
                                  value: label,
                                  child: Text(label),
                                ),
                            ],
                            onChanged: (value) => setState(() {
                              _unitLabel = value == null || value.isEmpty
                                  ? null
                                  : value;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) =>
                              ItemFormValidators.priceInput
                                      .hasMatch(newValue.text)
                                  ? newValue
                                  : oldValue,
                        ),
                      ],
                      decoration: InputDecoration(labelText: s.unitPrice),
                      validator: (v) => ItemFormValidators.requiredPrice(
                        v,
                        requiredMessage: s.unitPrice,
                        invalidMessage: s.priceFormat,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _store,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.storeLabel,
                        prefixIcon: const Icon(Icons.store_outlined),
                      ),
                      validator: (v) => ItemFormValidators.optionalName(
                        v,
                        s.lettersNumbersSpacesOnly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: _purchaseDate == null
                          ? s.purchaseDateLabel
                          : '${s.purchaseDateLabel}: ${df.format(_purchaseDate!)}',
                      icon: Icons.event_outlined,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 1),
                        );
                        if (picked != null) {
                          setState(() => _purchaseDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _buyer,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.buyerLabel,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => ItemFormValidators.optionalName(
                        v,
                        s.lettersNumbersSpacesOnly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: _expiryDate == null
                          ? s.pickExpiry
                          : '${s.expiryLabel}: ${df.format(_expiryDate!)}',
                      icon: Icons.schedule_rounded,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 10),
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      value: _recurring,
                      onChanged: (v) => setState(() => _recurring = v),
                      title: Text(s.recurringLabel),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.brand500,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(s.save),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static dynamic _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final s = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  List<String> _unitCountOptions(AppStrings s) {
    final options = [
      s.unitCountPiece,
      s.unitCountBottle,
      s.unitCountCan,
      s.unitCountBox,
      s.unitCountPack,
      s.unitCountBag,
      s.unitCountRoll,
      s.unitCountTube,
      s.unitCountSheet,
      s.unitCountPair,
      s.unitCountJar,
      s.unitCountPacket,
    ];
    final current = _unitLabel;
    if (current != null && !options.contains(current)) {
      options.insert(0, current);
    }
    return options;
  }
}

class _Back extends StatelessWidget {
  final VoidCallback onTap;
  const _Back({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  bool _handled = false;
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.scanBarcode)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      s.pointCameraAtBarcode,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor ??
              AppColors.neutral100,
          borderRadius: AppRadius.rMd,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.neutral500, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

