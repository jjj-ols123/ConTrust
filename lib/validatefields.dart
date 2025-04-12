import 'package:flutter/material.dart';

bool validateFieldsLogin(context, String email, String password) {
  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  return true;
}

bool validateFieldsContractor(context, String firmName, String contactNumber,
    String email, String password, String confirmPassword) {
  if (firmName.isEmpty ||
      contactNumber.isEmpty ||
      email.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  return true;
}

// ignore: unused_element
bool validateFieldsContractee(context, String fName, String lName, String email,
    String password, String confirmPass) {
  if (fName.isEmpty ||
      lName.isEmpty ||
      email.isEmpty ||
      password.isEmpty ||
      confirmPass.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  if (password != confirmPass) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  return true;
}

bool validateFieldsPostRequest(
  BuildContext context, String constructionType, String minBudget, String maxBudget, String startDate, 
  String location, String description, String duration) {
  if (constructionType.isEmpty ||
      minBudget.isEmpty ||
      maxBudget.isEmpty ||
      startDate.isEmpty ||
      location.isEmpty ||
      description.isEmpty ||
      duration.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  int minBudgetInt = int.tryParse(minBudget) ?? 0;
  int maxBudgetInt = int.tryParse(maxBudget) ?? 0;

  if (minBudgetInt > maxBudgetInt) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Minimum budget cannot exceed maximum budget'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  int durationInt = int.tryParse(duration) ?? 0;

  if (durationInt < 1 || durationInt > 30) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bid duration must be between 1 and 30 days'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  return true;
}
