import 'package:flutter/material.dart';

import '../../../shared/models/health_models.dart';
import 'interactive_booking_sheet.dart';

void showBookingSheet(BuildContext context, Doctor doctor) {
  showInteractiveBookingSheet(context, initialDoctor: doctor);
}
