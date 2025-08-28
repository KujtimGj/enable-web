import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../components/widgets.dart';

class ChatsList extends StatefulWidget {
  const ChatsList({super.key});

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        leadingWidth: 200,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 4),
              Text("Conversation history", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [customButton((){context.go("/");})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ResponsiveContainer(
              maxWidth: getWidth(context)*0.3,
              child: TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/icons/star-05.svg',
                    ),
                  ),
                  hintText: 'Search for conversations',
                  hintStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Text("25 Conversations in Enable",textAlign: TextAlign.start,),
            ResponsiveContainer(
              maxWidth: getWidth(context)*0.3,
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 25,
                itemBuilder: (context, index) {
                  return Container(
                    width: getWidth(context),
                    padding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    margin: EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xff1A1818),
                      border: Border.all(
                        color: Color(0xff292525),
                      ),
                      borderRadius: BorderRadius.circular(
                        5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          width: 30,
                          decoration: BoxDecoration(
                            color: Color(0xff1A1818),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(width: 1,color: Color(0xff292525))
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/chat.svg',
                            ),
                          ),
                        ),
                        Text('New conversation'),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
