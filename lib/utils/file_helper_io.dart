import 'dart:io';

dynamic createFile(String path) => path.isNotEmpty ? File(path) : null;
