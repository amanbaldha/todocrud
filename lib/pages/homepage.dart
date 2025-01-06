import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firepower/sevices/firestore.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {

  //firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();

  //text controller
  final TextEditingController textController = TextEditingController();


  //ope  dialog
  void openNoteBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          ElevatedButton(
              onPressed: (){
                //new note add
                final User? user = _auth.currentUser;
                if (user != null) {
                  if (docID == null) {
                    // firestoreService.addNote(textController.text);
                    _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('notes')
                        .add({'note': textController.text});
                  }
                  //update
                  else {
                    // firestoreService.updateNote(docID, textController.text);
                    _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('notes')
                        .doc(docID)
                        .update({'note': textController.text});
                  }
                }


                textController.clear();

                Navigator.pop(context);
              },
              child: Text(docID == null ? "Add" : "Update")),
        ],
      ),);
  }

  void signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }




  @override
  Widget build(BuildContext context) {

    final User? user = _auth.currentUser; // Step 3: Get the current logged-in user.

    if (user == null) {
      // If no user is logged in, display a fallback message.
      return const Center(child: Text('No user logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Notes")),
        backgroundColor: Colors.brown.shade300,
      actions: [
        IconButton(
          onPressed: signOut, // Step 4: Call the signOut method on logout.
          icon: const Icon(Icons.logout),
        ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: openNoteBox,
              child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // stream: firestoreService.getNotesStream(),
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            List notesList = snapshot.data!.docs;
            return ListView.builder(
                itemCount: notesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = notesList[index];
                  String docID = document.id;

                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String noteText = data['note'];

                  return ListTile(
                    title: Text(noteText),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min ,
                      children: [
                        //update
                        IconButton(
                          onPressed: () => openNoteBox(docID: docID),
                          icon: const Icon(Icons.edit),
                        ),
                        //delete
                        IconButton(
                          onPressed: () {
                            _firestore
                                .collection('users')
                                .doc(user.uid)
                                .collection('notes')
                                .doc(docID)
                                .delete();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    )
                  );
            },
            );
          } else{
            return const Text("No notes...");
          }
        },
      ),
    );
  }
}

