import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_server/aqueduct_server.dart';
import 'package:aqueduct_server/model/content.dart';
import 'package:aqueduct_server/model/page.dart';

class AdminContentController extends ResourceController {
  AdminContentController(this.context, this.authServer);

  final ManagedContext context;
  final AuthServer authServer;

  @Operation.get("pageId")
  Future<Response> getAllContents(@Bind.path("pageId") int pageId) async {
    final contentQuery = Query<Content>(context)..where((c) => c.page.id).equalTo(pageId);
    final contents = await contentQuery.fetch();
    return Response.ok(contents);
  }

  @Operation.post("pageId")
  Future<Response> createContent(@Bind.path("pageId") int pageId, @Bind.body() Content content) async {
    //check for page
    final pageQuery = Query<Page>(context)..where((o) => o.id).equalTo(pageId);
    final page = await pageQuery.fetchOne();
    if (page == null) {
      return Response.notFound();
    }

    final contentInsertQuery = Query<Content>(context)
      ..values = content
      ..values.page.id = page.id;

    final insertedContent =await contentInsertQuery.insert();
    return Response.ok(insertedContent);
  }
}