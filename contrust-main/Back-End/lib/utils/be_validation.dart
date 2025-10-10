import 'package:flutter/material.dart';
import 'be_snackbar.dart';

bool validateFieldsLogin(context, String email, String password) {
  if (email.isEmpty || password.isEmpty) {
    ConTrustSnackBar.error(context, 'Please fill in all fields');
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
    ConTrustSnackBar.error(context, 'Please fill in all fields');
    return false;
  }
  if (password != confirmPassword) {
    ConTrustSnackBar.error(context, 'Passwords do not match');
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
    ConTrustSnackBar.error(context, 'Please fill in all fields');
    return false;
  }

  if (password != confirmPass) {
    ConTrustSnackBar.error(context, 'Passwords do not match');
    return false;
  }

  return true;
}

bool validateFieldsPostRequest(BuildContext context, String title, String constructionType, String minBudget, String maxBudget, String startDate, 
  String location, String description, String duration) {
  if (constructionType.isEmpty ||
      minBudget.isEmpty ||
      maxBudget.isEmpty ||
      startDate.isEmpty ||
      location.isEmpty ||
      description.isEmpty ||
      duration.isEmpty) {
    ConTrustSnackBar.error(context, 'Please fill in all fields');
    return false;
  }

  int minBudgetInt = int.tryParse(minBudget) ?? 0;
  int maxBudgetInt = int.tryParse(maxBudget) ?? 0;

  if (minBudgetInt > maxBudgetInt) {
    ConTrustSnackBar.error(context, 'Minimum budget cannot be greater than maximum budget'
    );
    return false;
  }

  int durationInt = int.tryParse(duration) ?? 0;

  if (durationInt < 1 || durationInt > 30) {
    ConTrustSnackBar.error(context, 'Bid duration must be between 1 and 30 days');
    return false;
  }

  return true;
}

bool validateBidRequest(BuildContext context, String bidAmount, String message) {
  if (bidAmount.isEmpty || message.isEmpty) {
    ConTrustSnackBar.error(context, 'Please fill in all fields');
    return false;
  }

  int bidAmountInt = int.tryParse(bidAmount) ?? 0;

  if (bidAmountInt < 1) {
    ConTrustSnackBar.error(context, 'Bid amount must be greater than zero');
    return false;
  }

  return true;
}
