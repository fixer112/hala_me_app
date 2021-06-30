import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/home_screen.dart';
import 'package:hala_me/values.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final bool force;

  LoginScreen({Key? key, this.force = true}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController controller = TextEditingController();
  bool loading = false;
  final UserProvider provider = Get.put(UserProvider());
  @override
  void initState() {
    //print('login');
    currentChatPage = 0;
    getUser();

    super.initState();
  }

  getUser() async {
    loading = true;
    setState(() {});

    User? user = await provider.currentUser();
    //await Provider.of<UserProvider>(context, listen: false).currentUser();
    //print(user?.access_token);
    if (!widget.force && user?.access_token != null) {
      Get.off(HomeScreen(first: true));
    }

    await Future.delayed(Duration(seconds: 1));

    loading = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        //backgroundColor: Colors.grey,
        body: Container(
          margin: EdgeInsets.all(20),
          child: Center(
            child: Row(
              children: [
                Container(
                  width: Get.width * 0.7,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    //print(controller.text);
                    loading = true;
                    setState(() {});
                    await UserRepository.login(controller.text);
                    loading = false;
                    setState(() {});
                  },
                  child: loading == true ? loader() : Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
