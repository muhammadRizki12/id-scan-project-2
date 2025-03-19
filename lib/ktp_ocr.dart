import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktp_extractor/ktp_extractor.dart';
import 'package:flutter1/liveness_detection.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart'; // Tambahkan ini

class KTPAuthScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const KTPAuthScreen({super.key, required this.cameras});

  @override
  State<KTPAuthScreen> createState() => _KTPAuthScreenState();
}

class _KTPAuthScreenState extends State<KTPAuthScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _originalImage; // Gambar asli (untuk UI)
  File? _filteredImage; // Gambar setelah filter (untuk OCR)
  KtpModel? _ktpModel;
  bool _isLoading = false;
  final Map<String, TextEditingController> _controllers = {};
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KTP Extractor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_filteredImage != null) Image.file(_filteredImage!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          ElevatedButton(
            child: const Text('Take a Picture'),
            onPressed: () => _getImage(ImageSource.gallery),
          ),
          if (_ktpModel != null) _buildEditableFields(),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _originalImage = null;
      _filteredImage = null;
      _ktpModel = null;
      _isLoading = true;
    });

    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      _originalImage = File(pickedFile.path);
      setState(() {}); // Tampilkan gambar asli lebih cepat
      await _processFile(_originalImage!);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _processFile(File file) async {
    _ktpModel = null;
    _isLoading = true;
    setState(() {});

    // Jalankan pemrosesan di Isolate agar UI tidak lag
    _filteredImage = await compute(_applyFilters, file);

    // Jalankan OCR pada gambar yang sudah difilter
    _ktpModel = await KtpExtractor.extractKtp(_filteredImage!);
    _initializeControllers();

    _isLoading = false;
    setState(() {});
  }

  // Fungsi ini berjalan di Isolate untuk mempercepat proses
  static Future<File> _applyFilters(File imageFile) async {
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image != null) {
      // Resize gambar untuk optimasi performa
      image = img.copyResize(image, width: 800);

      // Konversi ke grayscale
      // image = img.grayscale(image);
      image = img.sketch(
        image,
        amount: 1,
        mask: image,
      );

      // Adjust brightness dan contrast menggunakan adjustColor
      // image = img.adjustColor(image, amount: 1.0);

      // sketch(Image src, {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance})

      // Untuk menambah ketajaman menggunakan convolution matrix
      // final kernel = [-1, -1, -1, -1, 9, -1, -1, -1, -1];
      // image = img.convolution(image, filter: kernel);

      // Simpan hasil filter
      final processedFile = File('${imageFile.path}_filtered.jpg');
      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 100));

      return processedFile;
    }

    return imageFile;
  }

  void _initializeControllers() {
    if (_ktpModel == null) return;

    DateTime? parseBirthDay(String? birthDay) {
      if (birthDay == null) return null;
      try {
        return DateFormat('dd-MM-yyyy').parse(birthDay);
      } catch (e) {
        return null;
      }
    }

    _controllers.clear();
    _controllers['Provinsi'] = TextEditingController(text: _ktpModel!.province);
    _controllers['Kota / Kabupaten'] =
        TextEditingController(text: _ktpModel!.city);
    _controllers['NIK'] = TextEditingController(text: _ktpModel!.nik);
    _controllers['Nama'] = TextEditingController(text: _ktpModel!.name);
    _controllers['Tempat Lahir'] =
        TextEditingController(text: _ktpModel!.placeBirth);
    _selectedDate = parseBirthDay(_ktpModel!.birthDay);
    _controllers['Tanggal Lahir'] = TextEditingController(
        text: _selectedDate != null
            ? DateFormat('dd-MM-yyyy').format(_selectedDate!)
            : _ktpModel?.birthDay ?? "");
    _controllers['Jenis Kelamin'] =
        TextEditingController(text: _ktpModel!.gender);
    _controllers['RT'] = TextEditingController(text: _ktpModel!.rt);
    _controllers['RW'] = TextEditingController(text: _ktpModel!.rw);
    _controllers['Kel/Desa'] =
        TextEditingController(text: _ktpModel!.subDistrict);
    _controllers['Kecamatan'] =
        TextEditingController(text: _ktpModel!.district);
    _controllers['Agama'] = TextEditingController(text: _ktpModel!.religion);
    _controllers['Status Perkawinan'] =
        TextEditingController(text: _ktpModel!.marital);
    _controllers['Pekerjaan'] =
        TextEditingController(text: _ktpModel!.occupation);
    _controllers['Kewarganegaraan'] =
        TextEditingController(text: _ktpModel!.nationality);
    _controllers['Berlaku Hingga'] =
        TextEditingController(text: _ktpModel!.validUntil);
  }

  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._controllers.keys.map((key) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _controllers[key],
              keyboardType: key == 'NIK' || key == 'RT' || key == 'RW'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: key,
                border: const OutlineInputBorder(),
              ),
              maxLength: key == 'NIK' ? 16 : null,
              readOnly: key == 'Tanggal Lahir',
              onTap: key == 'Tanggal Lahir'
                  ? () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                          _controllers['Tanggal Lahir']!.text =
                              DateFormat('dd-MM-yyyy').format(pickedDate);
                        });
                      }
                    }
                  : null,
            ),
          );
        }),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        FaceAuthScreen(cameras: widget.cameras)),
              );
            },
            child: const Text('Lanjut ke Liveness Detection'),
          ),
        ),
      ],
    );
  }
}
