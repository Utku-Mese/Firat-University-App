import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_uni/models/student_model.dart';
import 'package:my_uni/views/screens/student_info_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> parseStudents(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Student>((json) => Student.fromJson(json)).toList();
  }

  Future<List<Student>> fetchStudents() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.34:8000/api/students'));

    if (response.statusCode == 200) {
      //return parseStudents(response.body);
      final students = parseStudents(response.body);
      // isActive değeri 1 olan öğrencileri filtreler
      final activeStudents =
          students.where((student) => student.isActive == 1).toList();
      return activeStudents;
    } else {
      throw Exception('API request failed: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Student>>(
      future: fetchStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Could not retrieve data: ${snapshot.error}');
        } else {
          final students = snapshot.data;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                fetchStudents();
              });
            },
            child: ListView.builder(
              itemCount: students?.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return StudentInfoScreen(student: students[index]);
                      },
                    ));
                  },
                  title: Text(
                      " ${students?[index].name}  ${students?[index].surname}"),
                  subtitle: Text(students![index].department.toString()),
                  leading: CircleAvatar(
                    child: students[index].imageUrl == null
                        ? Text(students[index].name![0])
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(50.0),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      child: CachedNetworkImage(
                                        fit: BoxFit.contain,
                                        imageUrl: students[index].imageUrl!,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: students[index].imageUrl!,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                );
              },
              padding: const EdgeInsets.only(bottom: 20.0),
            ),
          );
        }
      },
    );
  }
}
