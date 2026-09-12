import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/incidents/presentation/providers/incident_provider.dart';
import 'features/authority/presentation/providers/authority_provider.dart';
import 'features/crew/presentation/providers/crew_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => AuthorityProvider()),
        ChangeNotifierProvider(create: (_) => CrewProvider()),
      ],
      child: const DisasterGuardApp(),
    ),
  );
}
