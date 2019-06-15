import 'aqueduct_server.dart';
import 'controller/admin/admin_content_controller.dart';
import 'controller/identity_controller.dart';
import 'controller/page_controller.dart';
import 'controller/register_controller.dart';
import 'controller/user_controller.dart';
import 'model/content.dart';
import 'model/page.dart';
import 'model/user.dart';
import 'utility/html_template.dart';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class AqueductServerChannel extends ApplicationChannel
    implements AuthRedirectControllerDelegate {
  final HTMLRenderer htmlRenderer = HTMLRenderer();
  AuthServer authServer;
  ManagedContext context;
  bool reloadTemplates;
  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));

    final config = AqueductServerConfiguration(options.configurationFilePath);
    context = contextWithConnectionInfo(config.database);
    reloadTemplates = config.reloadTemplates;



    final authStorage = ManagedAuthDelegate<User>(context);
    authServer = AuthServer(authStorage);
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiver
  /// of all [Request]s.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final router = Router();

    /* OAuth 2.0 Endpoints */
    router.route("/auth/token").link(() => AuthController(authServer));

    router
        .route("/auth/form")
        .link(() => AuthRedirectController(authServer, delegate: this));

    /* Create an account */
    router
        .route("/register")
        .link(() => Authorizer.basic(authServer))
        .link(() => RegisterController(context, authServer));

    /* Gets profile for user with bearer token */
    router
        .route("/me")
        .link(() => Authorizer.bearer(authServer))
        .link(() => IdentityController(context));

    /* Gets all users or one specific user by id */
    router
        .route("/users/[:id]")
        .link(() => Authorizer.bearer(authServer))
        .link(() => UserController(context, authServer));

    router
        .route("/admin/pages/[:id]")
        .link(() => Authorizer.bearer(authServer))
        .link(() => ManagedObjectController<Page>(context));


    router
        .route("/admin/pages/:pageId/contents/[:id]")
        .link(() => Authorizer.bearer(authServer))
        .link(() => AdminContentController(context, authServer));

    router
      .route("/admin/contents/[:id]")
      .link(() => Authorizer.bearer(authServer))
      .link(() => ManagedObjectController<Content>(context));

    router
        .route("files/*")
        .link(() => FileController("public/"));
    router
      .route("/[:slug]")
        .link(() => PageController(context, reloadTemplates: reloadTemplates, htmlRenderer: htmlRenderer)
    );
    
    return router;
  }

  /*
   * Helper methods
   */

  ManagedContext contextWithConnectionInfo(
      DatabaseConfiguration connectionInfo) {
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final psc = PostgreSQLPersistentStore(
        connectionInfo.username,
        connectionInfo.password,
        connectionInfo.host,
        connectionInfo.port,
        connectionInfo.databaseName);

    return ManagedContext(dataModel, psc);
  }

  @override
  Future<String> render(AuthRedirectController forController, Uri requestUri,
      String responseType, String clientID, String state, String scope) async {
    final map = {
      "response_type": responseType,
      "client_id": clientID,
      "state": state
    };

    map["path"] = requestUri.path;
    if (scope != null) {
      map["scope"] = scope;
    }

    return htmlRenderer.renderHTML("web/login.html", map);
  }
}

/// An instance of this class represents values from a configuration
/// file specific to this application.
///
/// Configuration files must have key-value for the properties in this class.
/// For more documentation on configuration files, see
/// https://pub.dartlang.org/packages/safe_config.
class AqueductServerConfiguration extends Configuration {
  AqueductServerConfiguration(String fileName) : super.fromFile(File(fileName));

  DatabaseConfiguration database;
  String apiBaseURL;
  bool reloadTemplates;

}
