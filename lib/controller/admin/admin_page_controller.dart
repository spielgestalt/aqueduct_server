import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_server/aqueduct_server.dart';
import 'package:aqueduct_server/model/page.dart';

class AdminPageController extends ResourceController {
  AdminPageController(this.context, this.authServer);

  final ManagedContext context;
  final AuthServer authServer;

  @Operation.get()
  Future<Response> getAllPages() async {

    final query = Query<Page>(context);
    final pages = await query.fetch();
    return Response.ok(pages);
  }
  @Operation.get("id")
  Future<Response> getPage(@Bind.path("id") int id) async {
    final query = Query<Page>(context)..where((o) => o.id).equalTo(id);
    final p = await query.fetchOne();
    if (p == null) {
      return Response.notFound();
    }

    if (request.authorization.ownerID != id) {
      // Filter out stuff for non-owner of user
    }

    return Response.ok(p);
  }
  @Operation.post()
  Future<Response> createPage(@Bind.body() Page page) async {
    final insertedPage = await context.insertObject(page);
    return Response.ok(insertedPage);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    if (operation.method == "GET") {
      if (operation.pathVariables.contains("id")) {
        return {"200": APIResponse("An object by its id.")};
      } else {
        return {"200": APIResponse("All objects.")};
      }
    }

    if (operation.method == "POST") {
      return {"200": APIResponse("A new Page")};
    }
    return null;
  }
}