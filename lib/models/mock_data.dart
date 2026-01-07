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

  static final pcrEncounters = [
    {
      'id': 'PCR-001',
      'patient': {
        'name': 'John Doe',
        'age': '45',
        'sex': 'Male',
        'birthDate': '1979-05-15',
      },
      'encounter': {
        'status': 'finished',
        'startTime': '2025-04-28T09:15:00',
        'endTime': '2025-04-28T10:30:00',
        'vehicle': 'Ambu-01',
        'licensePlate': 'RW-512',
        'driver': 'Samuel Kamanzi',
        'medic': 'Amelie Bosco',
        'physician': 'Thomas Müller',
      },
      'pcr': {
        'a': {
          'airway': 'Clear',
          'furtherEvaluation': 'No obstructions observed',
        },
        'b': {
          'breathing': 'Normal',
          'spo2': '98%',
          'respiratoryRate': '16/min',
          'furtherEvaluation': 'Regular breathing pattern',
        },
        'c': {
          'pulse': '72 bpm',
          'bloodPressure': '120/80',
          'capillaryRefill': '< 2s',
          'skinAppearance': 'Normal',
          'hemorrhage': 'None',
          'furtherEvaluation': 'Stable circulation',
        },
        'd': {
          'eyeOpening': '4 - Spontaneous',
          'verbalResponse': '5 - Oriented',
          'motorResponse': '6 - Obeys commands',
          'pupils': 'Equal and reactive',
          'gcs': '15',
          'furtherEvaluation': 'Alert and oriented',
        },
        'e': {
          'wounds': 'None',
          'burns': 'None',
          'furtherEvaluation': 'No visible injuries',
        },
      },
      'medications': [
        {'name': 'Paracetamol', 'dose': '500mg', 'route': 'Oral', 'time': '09:30'},
      ],
      'procedures': [
        {'name': 'IV Access', 'time': '09:20', 'location': 'Left forearm'},
        {'name': 'ECG Monitoring', 'time': '09:25'},
      ],
      'equipmentUsed': [
        {'name': 'IV Catheter', 'quantity': '1'},
        {'name': 'ECG Monitor', 'quantity': '1'},
      ],
      'handover': {
        'destination': 'Kigali Hospital',
        'handedOverTo': 'Dr. Smith',
        'condition': 'Stable',
        'notes': 'Patient stable, vitals normal',
      },
    },
    {
      'id': 'PCR-002',
      'patient': {
        'name': 'Jane Rose',
        'age': '32',
        'sex': 'Female',
        'birthDate': '1992-08-22',
      },
      'encounter': {
        'status': 'in-progress',
        'startTime': '2025-04-28T11:00:00',
        'vehicle': 'Ambu-04',
        'licensePlate': 'RW-445',
        'driver': 'Sarah Weber',
        'medic': 'Mara Uwase',
        'physician': 'Manfred Herzig',
      },
      'pcr': {
        'a': {
          'airway': 'Maintained',
          'furtherEvaluation': 'Oxygen mask applied',
        },
        'b': {
          'breathing': 'Labored',
          'spo2': '92%',
          'respiratoryRate': '22/min',
          'furtherEvaluation': 'Requires oxygen support',
        },
        'c': {
          'pulse': '110 bpm',
          'bloodPressure': '140/90',
          'capillaryRefill': '2-3s',
          'skinAppearance': 'Pale',
          'hemorrhage': 'Minor',
          'furtherEvaluation': 'Tachycardic, monitoring required',
        },
        'd': {
          'eyeOpening': '3 - To voice',
          'verbalResponse': '4 - Confused',
          'motorResponse': '5 - Localizes pain',
          'pupils': 'Equal and reactive',
          'gcs': '12',
          'furtherEvaluation': 'Altered mental status',
        },
        'e': {
          'wounds': 'Laceration right arm',
          'burns': 'None',
          'furtherEvaluation': 'Wound cleaned and dressed',
        },
      },
      'medications': [
        {'name': 'Morphine', 'dose': '5mg', 'route': 'IV', 'time': '11:15'},
      ],
      'procedures': [
        {'name': 'Wound Cleaning', 'time': '11:10'},
        {'name': 'Oxygen Administration', 'time': '11:05'},
      ],
      'equipmentUsed': [
        {'name': 'Oxygen Mask', 'quantity': '1'},
        {'name': 'IV Catheter', 'quantity': '1'},
      ],
      'handover': null,
    },
  ];
}