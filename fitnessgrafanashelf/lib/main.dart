import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/up', _getUpHandler)
  ..post('/uploadCsvData', _uploadCsvHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _getUpHandler(Request request) {
  return Response.ok('I am up');
}

Future<Response> _uploadCsvHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final map = jsonDecode(body);
    final conn = await Connection.open(Endpoint(
      host: Platform.environment["PG_HOST"]!,
      database: Platform.environment["PG_DB"]!,
      username: Platform.environment["PG_USER"]!,
      password: Platform.environment["PG_PASS"]!,
    ));
    // get the headers from the map
    List csvData = jsonDecode(map['entries']);
    String headers = csvData[0];
    var data = csvData.sublist(1);
    // comma separated string to list
    List<String> headerList = headers.split(',');
    // convert the data to a list of lists
    List dataList = data.map((e) {
      List temp = e.split(',');
      if (temp.length != headerList.length) {
        if (temp.isEmpty) {
          return null;
        }
        for (var i = 0; i < temp.length; i++) {
          if (temp[i].startsWith('"')) {
            String d = temp[i];
            // find the next occurrence of "
            int j = i + 1;
            while (!temp[j].endsWith('"')) {
              d = d + temp[j];
              j++;
            }
            d = d + temp[j];
            temp[i] = d;
            // remove the elements from i+1 to j
            temp.removeRange(i + 1, j + 1);
            // remove the quotes if they are at the start and end
            if (temp[i].startsWith('"')) {
              temp[i] = temp[i].substring(1);
            }
            if (temp[i].endsWith('"')) {
              temp[i] = temp[i].substring(0, temp[i].length - 1);
            }
            if (i == 0) {
              // Split the date string by space
              List<String> dateParts = temp[i].split(' ');

              // Map month names to their corresponding numeric values
              Map<String, int> monthMap = {
                "January": 1,
                "February": 2,
                "March": 3,
                "April": 4,
                "May": 5,
                "June": 6,
                "July": 7,
                "August": 8,
                "September": 9,
                "October": 10,
                "November": 11,
                "December": 12
              };

              // Extract day, month, and year components
              int day = int.parse(dateParts[1]);
              int month = monthMap[dateParts[0]]!;
              int year = int.parse(dateParts[2]);

              // Construct DateTime object
              DateTime dateTime = DateTime(year, month, day);
              temp[i] = dateTime.toIso8601String();
            }
          }
          if (i == 5 || i == 6 || i == 7 || i == 10 || i == 11) {
            // sometimes the value can be --g, so we need to replace it with 0
            if (temp[i].contains('--')) {
              temp[i] = '0';
            } else {
              // the values will be of the form 103g etc, so we need to remove the g
              temp[i] = temp[i].substring(0, temp[i].length - 1);
            }
          }
        }
      }
      return temp;
    }).toList();
    // delete the table if it already exists
    await conn.execute('DROP TABLE IF EXISTS csv_table');
    // create the table with the correct data types
    await conn.execute('''
  CREATE TABLE IF NOT EXISTS csv_table (
    ${headerList.map((e) {
      if (e.toLowerCase().contains('date')) {
        return '$e date';
      } else {
        return '$e text';
      }
    }).join(',')})
''');

    dataList.removeWhere((element) =>
        element == null ||
        element.isEmpty ||
        (element.length == 1 && element[0] == ''));

    // insert the data
    for (var row in dataList) {
      await conn.execute('''
      INSERT INTO csv_table (${headerList.join(',')})
      VALUES (${row.map((e) => "'$e'").join(',')})
    ''');
    }
    return Response.ok('Data uploaded');
  } catch (e) {
    print(e);
    return Response.internalServerError(body: 'Error: $e');
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  final overrideHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
  };
  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
