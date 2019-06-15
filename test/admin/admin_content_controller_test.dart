import 'package:aqueduct_server/model/user.dart';
import 'package:aqueduct_server/model/page.dart';
import 'package:aqueduct_server/model/content.dart';
import '../harness/app.dart';

Future main() async {
  Agent agent;
  int pageId;
  int contentId;
  final harness = Harness()
    ..install();

  setUp(() async {
    final user = User()
      ..username = "bob@stablekernel.com"
      ..password = "foobaraxegrind";
    agent = await harness.registerUser(user);
    final context = harness.channel.context;
    final insertPageQuery = Query<Page>(context)
      ..values.title = "Page1"
      ..values.slug = "page1"
      ..values.pageStatus = PageStatus.review;

    final page = await insertPageQuery.insert();

    final documentData = Document({"text": "Lorem Ipdum"});
    final contentQuery = Query<Content>(context)
      ..values.page.id = page.id
      ..values.position = 1
      ..values.contentType = ContentType.text
      ..values.contentData = documentData;
    final content = await contentQuery.insert();
    assert(content.page.id == page.id);
    contentId = content.id;
    pageId = page.id;

  });

  test("fetch all contents from page one", () async {
    final response = await agent.get("/admin/pages/$pageId/contents");
    expectResponse(response, 200);
    final List<Map<String, dynamic>> responsePages = await response.body.decode();
    expect(responsePages.length, 1);

  });

  test("fetch all contents", () async {
    final response = await agent.get("/admin/contents");
    expectResponse(response, 200);
    final List<Map<String, dynamic>> responsePages = await response.body.decode();
    expect(responsePages.length, 1);
  });

  test("fetch content by id", () async {
    final response = await agent.get("/admin/contents/$contentId");
    expectResponse(response, 200);
    expect(response, hasResponse(200, body: partial({
      "id": 1, "position": 1, "contentType": "text"
    })));
  });
}
