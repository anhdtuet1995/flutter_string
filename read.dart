import 'dart:async';
import 'dart:io';
import 'dart:convert';

final String textType = "text";
final jsonType = "json";
final codeType = "code";

final normalFormat = "#";
final camelFormat = "#^";
final typeFormat = "#^^";
final stringType = "string";

int convertToIndex(int code) {
  if (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) {
    return code - 'a'.codeUnitAt(0);
  } else if (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) {
    return code - 'A'.codeUnitAt(0);
  } else if (code >= '1'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
    return code - '1'.codeUnitAt(0);
  } else
    return -1;
}

List<String> getHeaders(String format) {}

Iterable<String> _allStringMatches(String text, RegExp regExp) =>
    regExp.allMatches(text).map((m) => m.group(0));

Config readFile(String configUrl) {
  final fileNameTitle = "excel_file_name";
  final formatTitle = "format";
  final startRowTitle = "start_row";
  final outputTypeTitle = "output_type";
  final prefixTitle = "prefix";
  final suffixTitle = "suffix";
  final returnTypeIndexTitle = "return_type_index";

  Config config = new Config();
  File file = new File(configUrl);
  try {
    List<String> fileContents = file.readAsLinesSync();
    for (String line in fileContents) {
      if (line.contains(fileNameTitle)) {
        //Lấy đường dẫn đến file excel
        String filePath = line.substring(fileNameTitle.length + 1);
        config.filePath = filePath;
      } else if (line.contains(formatTitle)) {
        //Lấy ra dạng format
        String format = line.substring(formatTitle.length + 1);
        config.format = format;
      } else if (line.contains(startRowTitle)) {
        //Lấy ra vị trí của dòng chưa thông tin các title
        String startRow = line.substring(startRowTitle.length + 1);
        config.startRow = int.parse(startRow);
      } else if (line.contains(outputTypeTitle)) {
        //Lấy ra vị trí của dòng chứa output type
        String outputType = line.substring(outputTypeTitle.length + 1);
        config.outputType = outputType;
      } else if (line.contains(prefixTitle)) {
        //Lấy ra vị trí của dòng chứa tiền tố
        String prefix = line.substring(prefixTitle.length + 1);
        config.prefix = prefix;
      } else if (line.contains(suffixTitle)) {
        //Lấy ra vị trí của dòng chứa hậu tố
        String suffix = line.substring(suffixTitle.length + 1);
        config.suffix = suffix;
      } else if (line.contains(returnTypeIndexTitle)) {
        //Lấy ra vị trí cột chứa thông tin giá trị trả về
        String returnTypeIndex = line.substring(returnTypeIndexTitle.length + 1);
        config.returnTypeIndex = returnTypeIndex;
      }
    }
    return config;
  } catch (e) {
    print("Something has wrong: ${e.toString()}");
    return null;
  }
}

String handleCamel(String text) {
  String result = "";
  List<String> splitedStrings = text.split("_");
  bool first = true;
  for (String str in splitedStrings) {
    if (first) {
      result += str;
      first = false;
    } else {
      result += str[0].toUpperCase() + str.substring(1);
    }
  }
  return result;
}

void handleOutputFile(String outputFileName, Map<String, GenerateModel> data, Config config, bool isJson) {
  File outputFile = new File(outputFileName);
  var outputStream = outputFile.openWrite();
  outputStream.writeln(config.prefix == null ? "" : config.prefix);
  if (config.headerIndexes.length > 0) {
    String firstKey = config.headerIndexes[0];
    int childCount = data[firstKey].value.length;
    for (int i = 0; i < childCount; i++) {
      String stringAfterFormat = config.format;
      if (isJson && i == childCount - 1) {
        if (stringAfterFormat.contains(',')) {
          stringAfterFormat = stringAfterFormat.replaceAll(',', '');
        }
      }
      for (int j = 0; j < config.headerIndexes.length; j++) {
        String currentKey = config.headerIndexes[j];
        String currentValue = data[currentKey].value[i];
        
        //Thay thế #A bằng text
        stringAfterFormat = stringAfterFormat.replaceAll(
            normalFormat + currentKey, currentValue);

        //Thay thế #^A bằng dạng camel
        String camel = handleCamel(currentValue);
        if (camel.length > 0) {
          stringAfterFormat = stringAfterFormat.replaceAll(
            camelFormat + currentKey,
            camel[0].toUpperCase() + camel.substring(1));
        }
        print("camel = ${camel} with length = ${camel.length}");


        //Thay thế #^^A bằng dạng type
        if (config.outputType == codeType && config.returnTypeIndex != null && config.returnTypeIndex.length > 0) {
          String returnType = data[config.returnTypeIndex].value[i];
          stringAfterFormat = stringAfterFormat.replaceAll(
            typeFormat + currentKey, (returnType != null && returnType.toLowerCase() == stringType ? "\"$currentValue\"" : currentValue));
        }
      }
      outputStream.writeln('\t${stringAfterFormat.replaceAll(RegExp(' +'), ' ')}');
    }
  }
  outputStream.writeln(config.suffix == null ? "" : config.suffix);
  outputStream.close();
}

main(List<String> params) {
  final configPath = params[0];
  final outputFileName = params[2];
  final inputFileName = params[1];
  

  if (configPath == null && configPath.length == 0) {
    return;
  }

  if (outputFileName == null && outputFileName.length == 0) {
    return;
  }

  if (inputFileName == null && inputFileName.length == 0) {
    return;
  }

  //Trường hợp lấy ra text thường
  RegExp reqExp = new RegExp(
    r"#\w",
    caseSensitive: false,
    multiLine: false,
  );

  //Trường hợp lấy ra text camel
  RegExp reqExpCamel = new RegExp(
    r"#\^\w",
    caseSensitive: false,
    multiLine: false,
  );

  //Trường hợp lấy ra text để convert dựa trên type
  RegExp reqExpCode = new RegExp(
    r"#\^\^\w",
    caseSensitive: false,
    multiLine: false,
  );

  Config config = readFile(configPath);
  config.filePath = inputFileName;

  if (config == null) {
    print("Something has wrong with config file!");
    return;
  }

  var path = config.filePath;
  String format = config.format;
  int startRow = config.startRow;
  List<String> headerIndexes = [];

  //lấy các index (A, B, C...) từ format
  for (var item in _allStringMatches(format, reqExp)) {
    if (!headerIndexes.contains(item)) {
      headerIndexes.add(item);
    }
  }

  for (var item in _allStringMatches(format, reqExpCamel)) {
    if (!headerIndexes.contains(item)) {
      headerIndexes.add(item);
    }
  }

  for (var item in _allStringMatches(format, reqExpCode)) {
    if (!headerIndexes.contains(item)) {
      headerIndexes.add(item);
    }
  }

  if (config.returnTypeIndex != null && config.returnTypeIndex.length > 0 && !headerIndexes.contains(config.returnTypeIndex)) {
    headerIndexes.add(config.returnTypeIndex);
  }

  final File file = new File(path);
  Stream<List> inputStream = file.openRead();
  List<List<String>> data = [];

  //Lưu kết quả đọc được từ file dưới dạng Map với key là các cột đọc trong file excel từ file config (#A, #B)
  //value là một object chứa key (nằm ở dòng đầu tiên trong file excel kể từ start_row (config file)) và value là danh sách các giá trị của từng key
  Map<String, GenerateModel> result = new Map();

  inputStream.transform(utf8.decoder).transform(new LineSplitter()).listen(
      (String line) {
    if (inputFileName.endsWith(".txt")) {
      List<String> row = line.split('\t');
      data.add(row);
      print(row);
    } else if (inputFileName.endsWith(".csv")) {
      List<String> row = line.split(new RegExp(r',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)', multiLine: false, caseSensitive: false));
      data.add(row);
    }
    
  }, onDone: () {
    if (data.length == 0) return;
    //đọc thông tin từ file csv
    for (var i = 0; i < headerIndexes.length; i++) {
      String excelIndex = headerIndexes[i];
      
      excelIndex = excelIndex.replaceAll(typeFormat, "");
      excelIndex = excelIndex.replaceAll(camelFormat, "");
      excelIndex = excelIndex.replaceAll(normalFormat, "");
      //Lấy vị trí cột hiện tại
      int x = convertToIndex(excelIndex.codeUnitAt(0));

      String key = "";
      List<String> value = [];
      for (var j = startRow; j < data.length; j++) {
        String row = data[j][x];
        row = row.replaceAll(new RegExp(r'\"\"', caseSensitive: false, multiLine: false), "");
        if (row.startsWith("\"") && row.endsWith("\"")) {
          if (row.length == 1 || row.length == 2) {
            row = "";
          } else {
            row = row.substring(1, row.length - 1);
          }
        }
        if (j == startRow) {
          key = row;
        } else {
          value.add(row);
        }
      }
      GenerateModel model = new GenerateModel(key, value);
      config.headerIndexes.add(excelIndex);
      result[excelIndex] = model;
    }

    //Xử lý để in ra file kết quả
    if (config.outputType == textType) {
      //In ra file dạng text
      handleOutputFile(outputFileName, result, config, false);
    } else if (config.outputType == jsonType) {
      //In ra file dạng json
      handleOutputFile(outputFileName, result, config, true);
    } else if (config.outputType == codeType) {
      //In ra file dạng json
      handleOutputFile(outputFileName, result, config, false);
    }
    print("File $outputFileName was generated successfully!");
  }, onError: (e) {
    print(e.toString());
  });
}

class Config {
  String filePath = "";
  int startRow = 0;
  String format = "";
  String outputType = "";
  List<String> headerIndexes = [];
  List<String> returnTypes = [];
  String prefix = "";
  String suffix = "";
  String returnTypeIndex = "";
}

class GenerateModel {
  String key;
  List<String> value;

  GenerateModel(this.key, this.value);

  @override
  String toString() {
    return "Model has key = $key and value = $value";
  }
}
