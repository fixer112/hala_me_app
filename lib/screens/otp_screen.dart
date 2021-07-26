import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/values.dart';
import 'package:numeric_keyboard/numeric_keyboard.dart';

class OTPScreen extends StatefulWidget {
  String number;
  OTPScreen(
    this.number, {
    Key? key,
  }) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  String text = '';

  bool loading = false;
  UserProvider provider = Get.put(UserProvider());
  void _onKeyboardTap(String value) {
    setState(() {
      if (text.length < 4) {
        text = text + value;
      }
    });
  }

  Widget otpNumberWidget(int position) {
    try {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Center(
            child: Text(
          text[position],
          style: TextStyle(color: Colors.black),
        )),
      );
    } catch (e) {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      //key: loginStore.otpScaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: primaryColor.withAlpha(20),
            ),
            child: Icon(
              Icons.arrow_back,
              color: primaryColor,
              size: 16,
            ),
          ),
          onPressed: () {
            logout(provider);
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        brightness: Brightness.light,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                        'Enter 4 digits verification code sent to your number',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.w500))),
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      otpNumberWidget(0),
                      otpNumberWidget(1),
                      otpNumberWidget(2),
                      otpNumberWidget(3),
                      //otpNumberWidget(4),
                      //otpNumberWidget(5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 500),
            child: RaisedButton(
              onPressed: loading == true
                  ? null
                  : () async {
                      //print(AppConfig.DOMAIN_PATH);
                      //print(widget.number);
                      //print(text);
                      if (text.length != 4) {
                        return snackbar("", 'OTP should be 4 digits');
                      }
                      loading = true;
                      setState(() {});
                      try {
                        await UserRepository.login(widget.number, otp: text);
                      } catch (e) {
                        print(e);
                        loading = false;
                      }
                      if (mounted) {
                        loading = false;
                        setState(() {});
                      }
                    },
              color: primaryColor,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                    loading == true
                        ? loader(scale: 0.5, center: false, color: Colors.white)
                        : Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              color: primaryColor,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                  ],
                ),
              ),
            ),
          ),
          NumericKeyboard(
            onKeyboardTap: _onKeyboardTap,
            textColor: primaryColor,
            rightIcon: Icon(
              Icons.backspace,
              color: primaryColor,
            ),
            rightButtonFn: () {
              setState(() {
                text = text.substring(0, text.length - 1);
              });
            },
          )
        ],
      ),
    );
  }
}
