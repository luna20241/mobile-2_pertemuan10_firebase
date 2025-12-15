import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final tugas = TextEditingController();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  void tambah() {
    final user = auth.currentUser;

    if (user != null && tugas.text.isNotEmpty) {
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('Todolist')
          .add({
            'tugas': tugas.text,
            'isCompleted': false, // Tambahkan field status selesai
            'CreateAt': Timestamp.now(),
          });
      tugas.clear();
    }
  }

  // Fungsi untuk toggle status selesai
  void toggleStatus(String docId, bool currentStatus) {
    final user = auth.currentUser;
    if (user != null) {
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('Todolist')
          .doc(docId)
          .update({'isCompleted': !currentStatus});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text("Halaman TodoList"),
        actions: [
          IconButton(onPressed: auth.signOut, icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('Todolist')
                  .orderBy('CreateAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada data tugas'));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final isCompleted = doc['isCompleted'] ?? false;
                    
                    return Card(
                      child: ListTile(
                        // Checkbox di leading
                        leading: Checkbox(
                          value: isCompleted,
                          onChanged: (value) {
                            toggleStatus(doc.id, isCompleted);
                          },
                        ),
                        // Teks tugas dengan coretan jika selesai
                        title: Text(
                          doc['tugas'],
                          style: TextStyle(
                            decoration: isCompleted 
                                ? TextDecoration.lineThrough 
                                : TextDecoration.none,
                            color: isCompleted 
                                ? Colors.grey 
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        // Tombol hapus
                        trailing: IconButton(
                          onPressed: () => doc.reference.delete(),
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tugas,
                    decoration: InputDecoration(
                      label: Text("Masukan Tugas"),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: tambah,
                  icon: Icon(Icons.send, size: 30, color: Colors.blue),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}