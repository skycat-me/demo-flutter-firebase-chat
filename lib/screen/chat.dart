import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/const.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const Chat(
      {@required this.peerId,
      @required this.peerName,
      @required this.peerAvatar,
      Key key})
      : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  String groupChatId;
  String id;
  var listMessage;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    groupChatId = '';

    readLocal();
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= widget.peerId.hashCode) {
      groupChatId = '$id-${widget.peerId}';
    } else {
      groupChatId = '${widget.peerId}-$id';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
          title: new Text(
            widget.peerName,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: WillPopScope(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildListMessage(),
                  // Input content
                  buildInput(),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildListMessage() => Flexible(
        child: groupChatId == ''
            ? Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
            : StreamBuilder(
                stream: Firestore.instance
                    .collection('messages')
                    .document(groupChatId)
                    .collection(groupChatId)
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor)));
                  } else {
                    listMessage = snapshot.data.documents;
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  }
                },
              ),
      );

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['idFrom'] == id) {
      return buildMyItem(index, document);
    } else {
      return buildPeerItem(index, document);
    }
  }

  Widget buildPeerItem(int index, DocumentSnapshot document) {
    const contentWidthSize = 200.0;
    const avatarSize = 35.0;

    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            children: <Widget>[
              Material(
                child: Image.network(
                  widget.peerAvatar,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(18.0),
                ),
              ),
              buildPeerInnerItem(index, document),
            ],
          ),
          // Time
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            margin: EdgeInsets.only(left: 10.0),
            width: contentWidthSize + avatarSize,
            child: buildTime(index, document),
          )
        ],
      ),
    );
  }

  Widget buildTime(int index, DocumentSnapshot document) => Container(
        child: Text(
          DateFormat('yyyy/MM/dd kk:mm').format(
            DateTime.fromMillisecondsSinceEpoch(
              int.parse(document['timestamp']),
            ),
          ),
          style: TextStyle(
            color: greyColor,
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      );

  Widget buildMyItem(int index, DocumentSnapshot document) => Container(
        margin: EdgeInsets.only(
            bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  child: Text(
                    document['content'],
                    style: TextStyle(color: primaryColor),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: greyColor,
                      borderRadius: BorderRadius.circular(8.0)),
                ),
              ],
            ),
            buildTime(index, document),
          ],
        ),
      );

  Widget buildPeerInnerItem(int index, DocumentSnapshot document) {
    switch (document['type']) {
      case 0:
        return buildPeerContent(index, document);
    }
  }

  Widget buildPeerContent(int index, DocumentSnapshot document) => Container(
        child: Text(
          document['content'],
          style: TextStyle(color: primaryColor),
        ),
        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        width: 200.0,
        decoration: BoxDecoration(
            color: greyColor2, borderRadius: BorderRadius.circular(8.0)),
      );

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Widget buildInput() => Container(
        child: Row(
          children: <Widget>[
            // Button send image
            Material(
              child: new Container(
                margin: new EdgeInsets.symmetric(horizontal: 1.0),
                child: new IconButton(
                  icon: new Icon(Icons.image),
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
            Material(
              child: new Container(
                margin: new EdgeInsets.symmetric(horizontal: 1.0),
                child: new IconButton(
                  icon: new Icon(Icons.face),
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),

            // Edit text
            Flexible(
              child: Container(
                child: TextField(
                  style: TextStyle(color: primaryColor, fontSize: 15.0),
                  controller: textEditingController,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: greyColor),
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),

            // Button send message
            Material(
              child: new Container(
                margin: new EdgeInsets.symmetric(horizontal: 8.0),
                child: new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: () => onSendMessage(textEditingController.text, 0),
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
        width: double.infinity,
        height: 50.0,
        decoration: new BoxDecoration(
            border:
                new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
            color: Colors.white),
      );

  /// メッセージ送信
  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      // Firestoreにセットする
      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': widget.peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }
}
