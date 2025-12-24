import 'dart:ui';

import 'package:aba_deeplink/membership/views/registration/registration_step_one.dart';
import 'package:aba_deeplink/views/face_rec_auth.dart';
import 'package:flutter/material.dart';
import 'package:blur/blur.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(11, 127, 23, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(11, 127, 23, 1),
        title: Text(
          'vKClub Membership',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          //Top Bar Area
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 10,
                ),
                Icon(
                  Icons.info,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                //User info area
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSEa75wK1Lvqzk3ZI5p1w2r532vlJMFsoL3aQ&s'),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, Vannputhika!',
                            style: TextStyle(
                                color: Color.fromRGBO(11, 127, 23, 1),
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          Text(
                            'View Profile',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                //Card Info
                Container(
                  height: MediaQuery.of(context).size.height * 0.20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Background Image with Blur
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://images.trvl-media.com/lodging/14000000/13070000/13062900/13062841/bd869bba.jpg?impolicy=resizecrop&rw=1200&ra=fit'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Blur Layer
                        BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 2.0,
                            sigmaY: 2.0,
                          ),
                          child: Container(
                              // color: Colors.white.withOpacity(0.1), // dak kr ban ort kr ban
                              ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //left side
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '0000000901',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  //vKPoint
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Available Balance',
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(.9),
                                            fontSize: 16),
                                      ),
                                      Text(
                                        '0000000901 vKPoints',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Expiring Tomorrow 0 vkPoints',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(.5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              //Right Side
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      'assets/vkirirom_logo.png',
                                      height: 100,
                                      width: 120,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen()));
                                    },
                                    child: Text('Student'),
                                    style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            Color.fromRGBO(11, 127, 23, 1)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                //6 button
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 10),
                //   child: Container(
                //     height: MediaQuery.of(context).size.height * 0.30,
                //     decoration: BoxDecoration(
                //       color: Colors.white.withOpacity(0.3),
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     child: GridView.builder(
                //         itemCount: 6,
                //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //             crossAxisCount: 3,mainAxisSpacing: 10,crossAxisSpacing: 10),
                //         itemBuilder: (context, index) {
                //           return Container(
                //             height: MediaQuery.of(context).size.height * 0.10,
                //             decoration: BoxDecoration(
                //               color: Colors.white,
                //               borderRadius: BorderRadius.circular(15),
                //             ),
                //             child: Center(
                //               child: Column(
                //                 mainAxisAlignment: MainAxisAlignment.center,
                //                 children: [
                //                   Icon(Icons.assistant_navigation),
                //                   Text('explore'),
                //                 ],
                //               ),
                //             ),
                //           );
                //         }),
                //   ),
                // ),
                GridLayout(items: gridItems),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.16,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: NetworkImage('https://cache2.travelfish.org/b/assets/2015/gallery/small/gallery_location_small_718_1458167687.jpg'),fit: BoxFit.cover)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GridItem {
  final IconData icon;
  final String name;
  final Color color;

  GridItem({required this.icon, required this.name, required this.color});
}

class GridItemWidget extends StatelessWidget {
  final GridItem item;

  const GridItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 50,
            color: Color.fromRGBO(11, 127, 23, 1),
          ),
          const SizedBox(height: 8),
          Text(item.name,style: TextStyle(color: Colors.black),),
        ],
      ),
    );
  }
}

class GridLayout extends StatelessWidget {
  final List<GridItem> items;

  const GridLayout({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        // height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          color: Color.fromRGBO(11, 127, 23, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: items.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => GridItemWidget(item: items[index]),
        ),
      ),
    );
  }
}

// Usage Example:
final gridItems = [
  GridItem(
      icon: Icons.explore,
      name: 'Explore',
      color: Color.fromRGBO(11, 127, 23, 1)),
  GridItem(icon: Icons.payment, name: 'Payment', color: Colors.green),
  GridItem(
      icon: Icons.home_repair_service,
      name: 'Services',
      color: Colors.deepPurple),
  GridItem(icon: Icons.call, name: 'Contacts', color: Colors.yellow),
  GridItem(icon: Icons.info, name: 'About', color: Colors.blueAccent),
  GridItem(icon: Icons.map, name: 'Map', color: Colors.red),
];
