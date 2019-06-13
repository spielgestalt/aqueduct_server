import 'package:aqueduct_server/model/page.dart';
import 'package:aqueduct_server/model/content.dart';

import 'harness/app.dart';
import 'harness/app.dart' as prefix0;
Future main() async {
  final harness = Harness()
    ..install();
  setUp(() async {
    final context = harness.channel.context;

    final insertHomePageQuery =  Query<Page>(context)
      ..values.title = "Homepage"
      ..values.slug = "homepage"
      ..values.isRoot = true
      ..values.pageStatus = PageStatus.published;

    final homepage = await insertHomePageQuery.insert();
    assert(homepage.slug == "homepage");


    final insertPageReviewQuery = Query<Page>(context)
      ..values.title = "Page1 in reviwe"
      ..values.slug = "page1"
      ..values.pageStatus = PageStatus.review;

    final reviewPage = await insertPageReviewQuery.insert();

    final documentData = Document({"text": "Lorem Ipdum"});
    final contentQuery = Query<Content>(context)
      ..values.page.id = reviewPage.id
      ..values.position = 1
      ..values.contentType = ContentType.text
      ..values.contentData = documentData;
    final content = await contentQuery.insert();
    assert(content.page.id == reviewPage.id);

    final insertPublishedPageQuery = Query<Page>(context)
      ..values.title = "Page2 in published"
      ..values.slug = "page2"
      ..values.pageStatus = PageStatus.published;

    final publishedPage = await insertPublishedPageQuery.insert();

    final publishedContentQuery = Query<Content>(context)
      ..values.page.id = publishedPage.id
      ..values.position = 1
      ..values.contentType = ContentType.text
      ..values.contentData = documentData;
    final publishedContent = await publishedContentQuery.insert();
    assert(publishedContent.page.id == publishedPage.id);



  });
  test("Get only pages which are 'published'", () async {
    final response = await harness.agent.get("/");
    expectResponse(response, 200);
    expect(response, hasResponse(200, body: partial({
      "title": "Homepage",
      "slug": "homepage",
      "pageStatus": "published"
    })));
  });

  test("Fetch published page by id", () async {
    final response = await harness.agent.get("/page2");
    expect(response, hasResponse(200, body: partial({
      "title": "Page2 in published",
      "slug": "page2",
      "pageStatus": "published"
    })));
  });

  test("Fetch review page by id should not be found", () async {
    final response = await harness.agent.get("/page1");
    expectResponse(response, 404);
  });

  test("Fetch not existing page by id should not be found", () async {
    final response = await harness.agent.get("/123123123");
    expectResponse(response, 404);
  });
}
