import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuscan/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await populateMockData();
  print('Mock data populated successfully!');
}

Future<void> populateMockData() async {
  final firestore = FirebaseFirestore.instance;

  final teachers = [
    {
      'id': 'T001',
      'name': 'Dr. Ali',
      'email': 'ali@campus.edu',
      'department': 'Computer Science',
    },
    {
      'id': 'T002',
      'name': 'Prof. Sara',
      'email': 'sara@campus.edu',
      'department': 'Software Engineering',
    },
  ];

  final courses = [
    {
      'code': 'CS-101',
      'name': 'Data Structures',
      'teacherId': 'T001',
      'time': '09:00 AM - 10:30 AM',
      'room': 'Room 301',
      'days': ['Mon', 'Wed'],
    },
    {
      'code': 'SE-2200',
      'name': 'Software Engineering',
      'teacherId': 'T001',
      'time': '11:00 AM - 12:30 PM',
      'room': 'Room 405',
      'days': ['Tue', 'Thu'],
    },
    {
      'code': 'CS-201',
      'name': 'Algorithm Design',
      'teacherId': 'T002',
      'time': '02:00 PM - 03:30 PM',
      'room': 'Room 202',
      'days': ['Mon', 'Wed', 'Fri'],
    },
  ];

  final students = [
    {'rollNo': '2021-CS-01', 'name': 'Ahmed Khan', 'section': 'A'},
    {'rollNo': '2021-CS-02', 'name': 'Fatima Noor', 'section': 'A'},
    {'rollNo': '2021-CS-03', 'name': 'Hassan Ali', 'section': 'A'},
    {'rollNo': '2021-CS-04', 'name': 'Zainab Shah', 'section': 'A'},
    {'rollNo': '2021-CS-05', 'name': 'Omar Raza', 'section': 'B'},
    {'rollNo': '2021-CS-06', 'name': 'Ayesha Malik', 'section': 'B'},
    {'rollNo': '2021-CS-07', 'name': 'Bilal Ahmed', 'section': 'B'},
    {'rollNo': '2021-CS-08', 'name': 'Sana Tariq', 'section': 'B'},
  ];

  final batch = firestore.batch();

  for (var teacher in teachers) {
    final docRef = firestore
        .collection('teachers')
        .doc(teacher['id'] as String);
    batch.set(docRef, teacher);
  }

  for (var course in courses) {
    final docRef = firestore
        .collection('courses')
        .doc(course['code'] as String);
    batch.set(docRef, course);
  }

  for (var student in students) {
    final docRef = firestore
        .collection('students')
        .doc(student['rollNo'] as String);
    batch.set(docRef, student);
  }

  await batch.commit();
}
