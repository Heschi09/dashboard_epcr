class MockData {
  static final alerts = [
    {'nr': '18', 'message': 'EKG Upload', 'time': '08:54', 'type': 'Info'},
    {'nr': '19', 'message': 'Vitalwerte', 'time': '08:40', 'type': 'Warn'},
    {'nr': '20', 'message': 'Batterie niedrig', 'time': '08:30', 'type': 'Warn'},
  ];

  static final openOrders = [
    {'nr': '#24019', 'title': 'Transfer Kigali', 'group': 'Crew A', 'time': '09:12'},
    {'nr': '#24023', 'title': 'Nachversorgung', 'group': 'Crew B', 'time': '08:47'},
    {'nr': '#24024', 'title': 'Notfall Einsatz', 'group': 'Crew C', 'time': '08:20'},
  ];

  static final crew = [
    {'group': 'A', 'name': 'Amelie', 'surname': 'Bosco', 'role': 'Paramedic'},
    {'group': 'B', 'name': 'Samuel', 'surname': 'Kamanzi', 'role': 'Driver'},
    {'group': 'C', 'name': 'Mara', 'surname': 'Uwase', 'role': 'Nurse'},
    {'group': 'A', 'name': 'Thomas', 'surname': 'Müller', 'role': 'Doctor'},
    {'group': 'B', 'name': 'Sarah', 'surname': 'Weber', 'role': 'Paramedic'},
    {'group': 'C', 'name': 'Manfred', 'surname': 'Herzig', 'role': 'Paramedic'},
  ];

  static final vehicles = [
    {'vehicle': 'Ambu-01', 'plate': 'RW-512', 'status': 'Available'},
    {'vehicle': 'Ambu-02', 'plate': 'RW-871', 'status': 'Maintenance'},
    {'vehicle': 'Rapid-03', 'plate': 'RW-334', 'status': 'On Mission'},
    {'vehicle': 'Ambu-04', 'plate': 'RW-445', 'status': 'Available'},
  ];

  static final equipment = [
    {'name': 'Monitor', 'qty': '12', 'target': '15'},
    {'name': 'Ventilator', 'qty': '6', 'target': '8'},
    {'name': 'Defibrillator', 'qty': '9', 'target': '12'},
    {'name': 'EKG Gerät', 'qty': '8', 'target': '10'},
  ];

  static final closedOrders = [
    {'nr': '#24010', 'title': 'Team Training', 'group': 'Crew A', 'time': '07:10'},
    {'nr': '#24011', 'title': 'Material Check', 'group': 'Crew C', 'time': '06:55'},
    {'nr': '#24012', 'title': 'Routine Check', 'group': 'Crew B', 'time': '06:30'},
  ];

  static final newOrders = [
    {'patient': 'John Doe', 'date': '2025-04-28', 'vehicle': 'Amb-01', 'crew': 'Bosco / Müller'},
    {'patient': 'Jane Rose', 'date': '2025-04-28', 'vehicle': 'Amb-04', 'crew': 'Kamanzi / Weber'},
    {'patient': 'Jacob Lee', 'date': '2025-04-27', 'vehicle': 'Amb-02', 'crew': 'Uwase / Herzig'},
  ];
}