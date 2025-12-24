import 'package:aba_deeplink/main.dart';
import 'package:aba_deeplink/views/homepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<IconData> bottomIcons = [
    Icons.home,
    Icons.qr_code_scanner,
    Icons.payment,
  ];
  int currentIndex = 0;
  late final List<Widget> page;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    page = [
      const HomePage(),
      ABA_DEEPLINK(),
      navBarPage(Icons.payment),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(11, 127, 23, 1),
      body: page[currentIndex],
      bottomNavigationBar: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            bottomIcons.length,
                (index) => GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex = index;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (index == 1) // QR code scanner icon
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        bottomIcons[index],
                        color: currentIndex == index
                            ? Color.fromRGBO(11, 127, 23, 1)
                            : Colors.white.withOpacity(0.5),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: currentIndex == index ? 25 : 0,
                      width: currentIndex == index ? 25 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            spreadRadius: currentIndex == index ? 10 : 0,
                            blurRadius: currentIndex == index ? 15 : 0,
                          )
                        ],
                      ),
                    ),
                  if (index != 1) // Other icons
                    Icon(
                      bottomIcons[index],
                      color: currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  navBarPage(iconName) {
    return Center(
      child: Icon(
        iconName,
        size: 100,
        color: Colors.white,
      ),
    );
  }
}
