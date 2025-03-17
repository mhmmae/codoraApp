
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../Get-Controllar/GetSerchController.dart';
import '../class/Chose-The-Type-Of-Item.dart';
import '../class/StreamBuilder-Box-Of-Item.dart';
import '../class/StreamBuilder-Box-Of-offer-Item.dart';
import '../class/StreamBuilder-Of-Search.dart';



class Home extends StatelessWidget {
   Home({super.key});
   TextEditingController search = TextEditingController();




   @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(


        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          leadingWidth: wi / 1.25,
          leading: Padding(
              padding: const EdgeInsets.only(left: 10, top: 0),
              child:GetBuilder<GetSearchController>(
                  init: GetSearchController()
                  , builder: (vall) {
                return TextFormFiled2(
                  wight: wi / 1.25,
                  fontSize: hi / 60,
                  height: hi / 40,
                  borderRadius: 12,
                  controller: search,
                  OnChange: (val) async {
                    vall.update();


                  },
                  validator: (val) {
                    if (val == null) {
                      return 'Eimpety';
                    }
                    return null;
                  },
                  label: 'Search ',
                  obscure: false,
                );
              })
          ),

        ),

        body:  GetBuilder<GetSearchController>(
            init: GetSearchController()
            , builder: (vall) {
          return search.text.isEmpty ?ListView(
            children: [
              SizedBox(
                height: hi / 50,
              ),


              StreambuilderBoxOfOfferItem(pageController: vall.pageController,),


              SizedBox(
                height: hi / 22,
              ),

              GetBuilder<Getchosethetypeofitem>(
                  init: Getchosethetypeofitem(), builder: (val) {
                return ChoseTheTypeOfItem();
              }),


              SizedBox(
                height: hi / 40,
              ),


              GetBuilder<Getchosethetypeofitem>(
                  init: Getchosethetypeofitem(), builder: (val) {
                return StreamBuilderBoxOfItem(TheChosen: val.TheChosen);
              })


            ],


          ):StreamBuilderOfSearch(search: search,);
        }


        )
    );
  }
}







