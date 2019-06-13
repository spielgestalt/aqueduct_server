import 'package:aqueduct_server/model/user.dart';
import 'package:aqueduct_server/model/page.dart';
import 'package:aqueduct_server/model/content.dart';
import '../harness/app.dart';
import '../harness/app.dart' as prefix0;

Future main() async {
  final harness = Harness()
    ..install();
  Agent agent;
  int testPageId;
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
    testPageId = page.id;
  });

  tearDown(() async {
    await harness.resetData();
  });

  test("Create Page in database", () async {
    final context = harness.channel.context;
    final insertPageQuery = Query<Page>(context)
      ..values.title = "A new Page title"
      ..values.slug = "a_new_page_title"
      ..values.pageStatus = PageStatus.review;
    final newPage = await insertPageQuery.insert();
    expect(newPage.title,"A new Page title");
  });

  test("POST /admin/pages unaothorized", () async {
    final response = await harness.agent.post("/admin/pages");
    expectResponse(response, 401);
  });

  test("POST /admin/pages", () async {

    final response = await agent.post("/admin/pages", body: {
      "title": "Page 2",
      "slug": "page_2",
      "pageStatus": "review"
    });
    expect(response, hasResponse(200, body: partial({
      "title": "Page 2",
      "slug": "page_2",
      "pageStatus": "review"
    })));
    //final query = new Query<Page>(context)
    //  ..where((record) => record.id).equalTo(response.body.as<Map>()['id']);

  });

  test("GET /admin/pages/[:id]", () async {
    final response = await agent.get("/admin/pages/${testPageId}");
    expect(response, hasResponse(200, body: partial({
      "title": "Page1",
      "pageStatus": "review"
    })));
  });

  test("GET /admin/pages", () async {
    final context = harness.channel.context;
    final pages = await Query<Page>(context).fetch();
    expect(pages.length, 1);
    final response = await agent.get("/admin/pages");
    final List<Map<String, dynamic>> responsePages = await response.body.decode();
    expectResponse(response, 200);
    expect(responsePages.length,1);
    expect(responsePages.first["title"], "Page1");
    //expect(response, hasBody(partial([{"title":"Page1"}])));
    //expectResponse(response, 200);
    /*expect(response, hasResponse(200, body: partial({
      "title": "Page1"
    })));*/

  });

}
