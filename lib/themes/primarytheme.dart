import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData primTheme() =>
    ThemeData(

        scaffoldBackgroundColor: backgroundBeige,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0, style: BorderStyle.none),
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.white,
            backgroundColor: buttonGreen,
            textStyle: TextStyle(fontFamily: 'segoeui', fontSize: 20),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(
                fontFamily: 'segoeui', fontSize: 20, color: darkGreen),
          ),
        ),


        textTheme: TextTheme(
            bodyLarge: TextStyle(color: darkGreen, decorationThickness: 0)),

        inputDecorationTheme: InputDecorationTheme(

          focusColor: darkGreen,
          fillColor: lightGrey,

          filled: true,

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 1.5, color: darkGreen),

          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 1.5, color: Colors.redAccent),

          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 1.5, color: Colors.redAccent),

          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 0, style: BorderStyle.none,),

          ),
          labelStyle: TextStyle(
              color: darkGreen, fontFamily: 'segoeui', fontSize: 20),

        ),

        textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkGreen,
            selectionHandleColor: buttonGreenOpacity,
            selectionColor: buttonGreenOpacity
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundBeige,
          foregroundColor: darkGreen,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: lightGrey,
          indicatorColor: lightGrey,
          iconTheme: WidgetStateProperty.all(IconThemeData(color: darkGreen)),
          labelTextStyle: WidgetStateProperty.all(TextStyle(color: darkGreen,
              fontFamily: 'segoeui',
              fontWeight: FontWeight.bold),),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
            color: darkGreen
        ),
        dropdownMenuTheme: DropdownMenuThemeData(

          inputDecorationTheme: InputDecorationTheme(

            focusColor: darkGreen,
            fillColor: lightGrey,

            filled: true,

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(width: 1.5, color: darkGreen),

            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(width: 1.5, color: Colors.redAccent),

            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(width: 1.5, color: Colors.redAccent),

            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(width: 0, style: BorderStyle.none,),

            ),
            labelStyle: TextStyle(
                color: darkGreen, fontFamily: 'segoeui', fontSize: 20),

          ),

        ),

      );

