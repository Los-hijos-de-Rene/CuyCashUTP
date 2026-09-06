import '../../env/app_flavor.dart';
import '../app_dependencies.dart';
import 'shared/shared_supabase_dependencies.dart';

Future<AppDependencies> buildLocalDependencies() =>
    buildSharedSupabaseDependencies(AppFlavor.local);
