import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData primTheme() =>
    ThemeData(
      scaffoldBackgroundColor: backgroundBeige,
      colorScheme: const ColorScheme.light(primary: Color.fromARGB(255, 62, 81, 56)),
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
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        contentTextStyle: TextStyle(
            fontSize: 16, fontFamily: 'segoeui', color: backgroundBeige),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: 'segoeui',
            fontSize: 20,
            color: darkGreen,
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: darkGreen,
          decorationThickness: 0,
          fontFamily: "segoeui",
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: lightGrey,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(width: 1.5, color: darkGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(width: 1.5, color: Colors.redAccent),
        ),
        errorMaxLines: 4,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(width: 1.5, color: Colors.redAccent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
        ),
        labelStyle: TextStyle(
          color: darkGreen,
          fontFamily: 'segoeui',
          fontSize: 20,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: darkGreen,
        selectionHandleColor: buttonGreenOpacity,
        selectionColor: buttonGreenOpacity,
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
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: darkGreen,
            fontFamily: 'segoeui',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: darkGreen),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundBeige,
        titleTextStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 18,
          color: darkGreen,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 18,
          color: darkGreen,
        ),

      ),
      indicatorColor: darkGreen,

      timePickerTheme: TimePickerThemeData(
        backgroundColor: backgroundBeige,
        hourMinuteTextColor: darkGreen,

        dialHandColor: darkGreen,

        dialBackgroundColor:backgroundBeige,
        hourMinuteColor: lightGrey.withOpacity(0.2),
        entryModeIconColor: darkGreen,
        cancelButtonStyle: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(wishListIcon)
        ),

        confirmButtonStyle: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(darkGreen)
        ),


        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        helpTextStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 16,
          color: darkGreen,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: lightGrey,
          filled: true,

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 1.5, color: darkGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 0, style: BorderStyle.none),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(width: 0, style: BorderStyle.none),
          ),
          labelStyle: TextStyle(
            color: darkGreen,
            fontFamily: 'segoeui',
            fontSize: 20,
          ),

        ),

      ),



      datePickerTheme: DatePickerThemeData(

        cancelButtonStyle: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(wishListIcon)
        ),
        confirmButtonStyle: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(darkGreen)
        ),
        backgroundColor: backgroundBeige,
        headerBackgroundColor: darkGreen,
        headerForegroundColor: Colors.white,
        weekdayStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 16,
          color: darkGreen,
        ),
        dayStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 16,
          color: darkGreen,

        ),


        dayOverlayColor: MaterialStateProperty.all(buttonGreenOpacity),


        yearBackgroundColor: MaterialStateProperty.all(lightGrey),
        yearForegroundColor: MaterialStateProperty.all(Colors.white),
        rangeSelectionBackgroundColor: buttonGreen.withOpacity(0.3),
        rangeSelectionOverlayColor: MaterialStateProperty.all(buttonGreen.withOpacity(0.2)),
        rangePickerBackgroundColor: darkGreen,
        yearStyle: TextStyle(
          fontFamily: 'segoeui',
          fontSize: 18,
          color: darkGreen,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );