import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/home_screen.dart';
import 'package:hala_me/screens/otp_screen.dart';
import 'package:hala_me/values.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  GlobalKey<FormState> _formKey = GlobalKey();
  String phoneNumber = "";
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
          //backgroundColor: Theme.of(context).primaryColor,
          body:
              /* Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  IntlPhoneField(
                    countries: ["NG"],
                    initialCountryCode: 'NG',
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      // border: OutlineInputBorder(
                      //   borderSide: BorderSide(),
                      // ),
                    ),
                    onChanged: (phone) {
                      //print(phone.completeNumber);
                      phoneNumber = phone.completeNumber;
                    },
                    onCountryChanged: (phone) {
                      //print('Country code changed to:  ${phone.countryCode}');
                      //print(phone.completeNumber);
                      phoneNumber = phone.completeNumber;
                    },
                  ),
                  /*  TextField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                  ),
                ), */
                  Center(
                    child: Container(
                      /*  constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.80,
                        ), */
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () async {
                          bool check =
                              _formKey.currentState?.validate() as bool;
                          if (check == true) {
                            phoneNumber = phoneNumber.replaceFirst('+', '');
                            print(phoneNumber);
                            //print(controller.text);
                            loading = true;
                            setState(() {});
                            try {
                              await UserRepository.login(phoneNumber);
                            } catch (e) {
                              print(e);
                              loading = false;
                            }
                            loading = false;
                            setState(() {});
                          }
                        },
                        child: loading == true
                            ? loader(
                                scale: 0.5, center: false, color: Colors.white)
                            : Text(
                                "Login",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
       */
              Center(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: <TextSpan>[
                          TextSpan(
                              text: 'We will send you an ',
                              style: TextStyle(color: primaryColor)),
                          TextSpan(
                              text: 'One Time Password ',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: 'on this mobile number',
                              style: TextStyle(color: primaryColor)),
                        ]),
                      )),
                  Container(
                    height: 40,
                    constraints: const BoxConstraints(maxWidth: 500),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: CupertinoTextFormFieldRow(
                      validator: (value) {
                        if (value?.length != 10) {
                          return "Invalid Phone Number";
                        }
                      },
                      prefix: Container(
                        //height: 20,

                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        //height: 40,
                        //constraints: const BoxConstraints(maxWidth: 500),

                        child: Text('+234'),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      controller: controller,
                      //clearButtonMode: OverlayVisibilityMode.editing,
                      keyboardType: TextInputType.phone,
                      maxLines: 1,
                      //placeholder: '',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: RaisedButton(
                      onPressed: loading == true
                          ? null
                          : () async {
                              //return Get.to(OTPScreen());
                              //print(AppConfig.DOMAIN_PATH);
                              bool check =
                                  _formKey.currentState?.validate() as bool;
                              if (check == true) {
                                phoneNumber =
                                    "234${controller.text}"; //.replaceFirst('+', '');
                                print(phoneNumber);
                                //print(controller.text);
                                loading = true;
                                setState(() {});
                                //try {
                                //print('test');
                                await UserRepository.login(phoneNumber);
                                /* } catch (e) {
                                  print(e);
                                  loading = false;
                                } */
                                if (mounted) {
                                  loading = false;
                                  setState(() {});
                                }
                              }
                            },
                      color: primaryColor,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Next',
                              style: TextStyle(color: Colors.white),
                            ),
                            loading == true
                                ? loader(
                                    scale: 0.5,
                                    center: false,
                                    color: Colors.white)
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
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
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
