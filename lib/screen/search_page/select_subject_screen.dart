import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SelectSubjectScreen extends StatefulWidget {
  final String inputRoute;
  final String termid;
  const SelectSubjectScreen(this.termid, this.inputRoute, {super.key});

  @override
  State<SelectSubjectScreen> createState() => _SelectSubjectScreenState();
}

class _SelectSubjectScreenState extends State<SelectSubjectScreen> {
  final db = FirebaseFirestore.instance;
  static List<String> dbSubjectList = [];
  late List<String> displayList = [];
  late String lastRoute;
  bool isLiked = false;
  Map favorite = {};
  Map dbFavorite = {};
  late List gradeData;
  late List scoreData;

  getUserUid() {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        return (FirebaseAuth.instance.currentUser?.uid)!;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        print("user not found in");
        return e.code.toString();
      }
    }
  }

  initFavorite() async {
    late String docid;
    String userUid = getUserUid();
    final query =
        await db.collection("학생").where("uuid", isEqualTo: userUid).get();
    docid = query.docs.first.id;
    final data = await db.collection("학생").doc(docid).get();
    dbFavorite = data['favorite'];
    try {
      if (data['favorite'][widget.termid] != null) {
        setState(
          () {
            dbFavorite = data['favorite'];
            favorite = data['favorite'][widget.termid];
          },
        );
      } else {
        dbFavorite[widget.termid] = {};
        await db.collection("학생").doc(userUid).update(
          {
            "favorite": dbFavorite,
          },
        );
      }
    } catch (e) {
      await db.collection("학생").doc(userUid).update(
        {
          "favorite": {},
        },
      );
      print("DBERORR OCURRED $e");
    }
  }

  Future getScoreData() async {}

  dataTest() async {
    gradeData = [];
    scoreData = [];
    final String docid = getUserUid();
    final userData = await db.collection("학생").doc(docid).get();
    final term = [];
    Map favoriteData = userData['favorite'];
    for (var term in favoriteData.keys) {
      Map subjectData = favoriteData[term];
      for (var subject in subjectData.keys) {
        if (subjectData[subject]['학점'] != null) {
          scoreData.add(subjectData[subject]['학점']);
        }
        if (subjectData[subject]['점수'] != null &&
            subjectData[subject]['점수'] != "") {
          gradeData.add(subjectData[subject]['점수']);
        }
      }
    }
    setState(() {
      scoreData = scoreData;
      gradeData = gradeData;
    });
    //print(gradeData);
    print(scoreData);
    //calGradeData();
    calScoreData();
  }

  String calScoreData() {
    double resultScore = 0;
    for (var score in scoreData) {
      resultScore = resultScore + double.parse(score);
    }
    print(resultScore);
    return resultScore.toString();
  }

  String calGradeData() {
    double gradeScore = 0;
    for (var score in gradeData) {
      switch (score) {
        case "A+":
          {
            gradeScore = gradeScore + 4.5;
            break;
          }
        case "A0":
          {
            gradeScore = gradeScore + 4.0;
            break;
          }
        case "B+":
          {
            gradeScore = gradeScore + 3.5;
            break;
          }
        case "B0":
          {
            gradeScore = gradeScore + 3.0;
            break;
          }
        case "C+":
          {
            gradeScore = gradeScore + 2.5;
            break;
          }
        case "C0":
          {
            gradeScore = gradeScore + 2.0;
            break;
          }
        case "D+":
          {
            gradeScore = gradeScore + 1.5;
            break;
          }
        case "D0":
          {
            gradeScore = gradeScore + 1.0;
            break;
          }
        case "F":
          {
            gradeScore = gradeScore + 0;
            break;
          }
      }
    }
    print(gradeScore);
    return gradeScore.toString();
  }

  toggleFavorite(String value) async {
    final collRef = db.collection(widget.inputRoute).doc(widget.termid);
    final data = await collRef.get();
    setState(() {
      if (favorite[value] != null) {
        favorite.remove(value);
      } else {
        favorite[value] = data[value];
      }
    });
    late String docid;
    String userUid = getUserUid();
    final query =
        await db.collection("학생").where("uuid", isEqualTo: userUid).get();
    docid = query.docs.first.id;
    dbFavorite[widget.termid] = favorite;
    await db.collection("학생").doc(docid).update({
      "favorite": dbFavorite,
    });
  }

  collectSubjectList() async {
    print("여기는 과목 선택 페이지");
    lastRoute = "${widget.inputRoute}/${widget.termid}";
    dbSubjectList = [];
    final collRef = db.collection(widget.inputRoute).doc(widget.termid);
    final data = await collRef.get();
    for (var subjectId in data.data()!.keys) {
      dbSubjectList.add(subjectId);
    }
    setState(() {
      displayList = List.from(dbSubjectList.toSet().toList());
      lastRoute = lastRoute;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    initFavorite();
    collectSubjectList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("과목 선택"),
        actions: [
          IconButton(
              onPressed: () {
                print("눌렀음");
                dataTest();
              },
              icon: const Icon(Icons.tab))
        ],
      ),
      body: displayList.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                if (favorite[displayList[index]] != null) {
                  isLiked = true;
                } else {
                  isLiked = false;
                }

                {
                  return Container(
                    child: ListTile(
                      onTap: () {
                        toggleFavorite(displayList[index]);
                      },
                      //trailing: const Icon(Icons.hub_outlined),
                      title: Text(
                        displayList[index],
                      ),
                      leading: IconButton(
                        icon: isLiked
                            ? const Icon(
                                Icons.favorite_outlined,
                                color: Colors.red,
                              )
                            : const Icon(
                                Icons.favorite_border_outlined,
                                color: Colors.red,
                              ),
                        onPressed: () {
                          toggleFavorite(displayList[index]);
                        },
                      ),
                      // leading: IconButton(
                      //   icon: isLiked
                      //       ? const Icon(
                      //           Icons.favorite_outlined,
                      //           color: Colors.red,
                      //         )
                      //       : const Icon(
                      //           Icons.favorite_border_outlined,
                      //           color: Colors.red,
                      //         ),
                      //   onPressed: () {
                      //     toggleFavorite(displayList[index]);
                      //   },
                      // ),
                      subtitle: const Text("subtitle"),
                    ),
                  );
                }
                return null;
              },
              itemCount: displayList.length,
            ),
    );
  }
}
