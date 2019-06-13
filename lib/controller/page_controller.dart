import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_server/aqueduct_server.dart';
import 'package:aqueduct_server/model/page.dart';
import 'package:aqueduct_server/utility/html_template.dart';
import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart';
import 'package:path/path.dart';

class PageController extends ResourceController {
  PageController(this.context, {@required this.htmlRenderer, @required this.reloadTemplates }) {
    if (reloadTemplates == false) {
      initializeTemplateEngine();
    }
  }
  final bool reloadTemplates;
  var _partialTemplates = <String, Template>{};
  Template _layoutTemplate;

  void initializeTemplateEngine() {
    _partialTemplates = {};
    _layoutTemplate = null;
    Directory("templates/").listSync(recursive: true, followLinks: true).forEach((entity) {
      print(entity.path);
      final fileName = basename(entity.path);
      if (fileName.startsWith("_") && fileName.endsWith(".mustache")) {
        print("found a partial");
        const regexString = r'^_(\w+)\.mustache$';
        final matches = RegExp(regexString).allMatches(fileName);
        final match = matches.first;
        final key = match.group(1);
        final content = File(entity.path).readAsStringSync();
        //_mustachePartials[key] = content;
        _partialTemplates[key] = Template(content, name: key);
      }
    });
    final layoutContent = File("templates/layout.mustache").readAsStringSync();
    _layoutTemplate = Template(layoutContent, partialResolver: (name) {
      final partial = _partialTemplates[name];
      return partial;
    });
  }

  final ManagedContext context;
  final HTMLRenderer htmlRenderer;
  @Operation.get()
  Future<Response> getRoot() async {
    final query = Query<Page>(context)
      ..where((page) => page.pageStatus).equalTo(PageStatus.published)
      ..where((page) => page.isRoot).equalTo(true);
    query.join(set: (page) => page.contents);
    final p = await query.fetchOne();
    if (p == null) {
      return _notFound;
    }
    if (reloadTemplates == true) {
      initializeTemplateEngine();
    }

    final result = _layoutTemplate.renderString(p.asMap());
    return Response.ok(result)..contentType = ContentType.html;
  }

  @Operation.get("slug")
  Future<Response> getPage(@Bind.path("slug") String slug) async {
    final query = Query<Page>(context)
      ..where((page) => page.slug).equalTo(slug)
      ..where((page) => page.pageStatus).equalTo(PageStatus.published);
    query.join(set: (page) => page.contents);

    final p = await query.fetchOne();
    if (p == null) {

      return _notFound;
    }
    if (reloadTemplates == true) {
      initializeTemplateEngine();
    }

    final result = _layoutTemplate.renderString(p.asMap());
    return Response.ok(result)..contentType = ContentType.html;
  }
  Response get _notFound  {
    final notFoundResponse = Response.notFound();
    if (request.acceptsContentType(ContentType.html)) {
      notFoundResponse
        ..body = "<html lang='en'><h3>404 Not Found</h3></html>"
        ..contentType = ContentType.html;
    }
    return notFoundResponse;
  }
}