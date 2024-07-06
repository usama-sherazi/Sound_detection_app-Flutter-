import 'package:flutter/material.dart';

class Homepage extends StatelessWidget{
  const Homepage({super.key});



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'Sound Detection App',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sound Detector App'),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
           IconButton(
             onPressed: (){},
               icon: const Icon(Icons.settings) ) ,
]
        ),
        body: const Center(
          child: Text('Listening for sounds...'),
        ),
      ),
    );
  }
}
