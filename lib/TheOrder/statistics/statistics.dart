
import 'package:flutter/material.dart';

class statistics extends StatelessWidget {
  const statistics({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: hi/15,),
          Center(child:Container(decoration: BoxDecoration(
            color:Colors.green,
            borderRadius:BorderRadius.circular(7),
          ),child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:6),
            child: Text('احصائيات'),
          ))),
          SizedBox(height: hi/40,),

          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              height: hi/9,
              width: wi,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black26
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10,vertical:2),
                child: Row(
                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                  children:[
                    Column(
                      mainAxisAlignment:MainAxisAlignment.spaceBetween,
                      children: [
                        Text("هذا اليوم"),
                        SizedBox(height:hi/100)
                      ],
                    ),
                    Column(
                      mainAxisAlignment:MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height:hi/100),
                        Container(decoration:BoxDecoration(
                          color:Colors.green,
                          borderRadius:BorderRadius.circular(10)
                        ),child: Row(
                          children: [
                            SizedBox(width:wi/50),
                            Text("10000000 DIQ",style:TextStyle(color:Colors.white)),
                            SizedBox(width:wi/50),

                          ],
                        )),
                      ],
                    )
                  ]
                ),
              )

            ),
          ),
          SizedBox(height: hi/90,),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                height: hi/9,
                width: wi,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black26
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical:2),
                  child: Row(
                      mainAxisAlignment:MainAxisAlignment.spaceBetween,
                      children:[
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            Text("هذا الشهر"),
                            SizedBox(height:hi/100)
                          ],
                        ),
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height:hi/100),
                            Container(decoration:BoxDecoration(
                                color:Colors.green,
                                borderRadius:BorderRadius.circular(10)
                            ),child: Row(
                              children: [
                                SizedBox(width:wi/50),
                                Text("10000000 DIQ",style:TextStyle(color:Colors.white)),
                                SizedBox(width:wi/50),

                              ],
                            )),
                          ],
                        )
                      ]
                  ),
                )

            ),
          ),
          SizedBox(height: hi/90,),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                height: hi/9,
                width: wi,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black26
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical:2),
                  child: Row(
                      mainAxisAlignment:MainAxisAlignment.spaceBetween,
                      children:[
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            Text("هذه السنة"),
                            SizedBox(height:hi/100)
                          ],
                        ),
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height:hi/100),
                            Container(decoration:BoxDecoration(
                                color:Colors.green,
                                borderRadius:BorderRadius.circular(10)
                            ),child: Row(
                              children: [
                                SizedBox(width:wi/50),
                                Text("10000000 DIQ",style:TextStyle(color:Colors.white)),
                                SizedBox(width:wi/50),

                              ],
                            )),
                          ],
                        )
                      ]
                  ),
                )

            ),
          ),
          SizedBox(height: hi/90,),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                height: hi/9,
                width: wi,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black26
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical:2),
                  child: Row(
                      mainAxisAlignment:MainAxisAlignment.spaceBetween,
                      children:[
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            Text("الكل"),
                            SizedBox(height:hi/100)
                          ],
                        ),
                        Column(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height:hi/100),
                            Container(decoration:BoxDecoration(
                                color:Colors.green,
                                borderRadius:BorderRadius.circular(10)
                            ),child: Row(
                              children: [
                                SizedBox(width:wi/50),
                                Text("10000000 DIQ",style:TextStyle(color:Colors.white)),
                                SizedBox(width:wi/50),

                              ],
                            )),
                          ],
                        )
                      ]
                  ),
                )

            ),
          )
        ],
      ) ,
    );
  }
}
