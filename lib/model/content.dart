import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_server/aqueduct_server.dart';
import '../model/page.dart';

enum ContentType {
  text,
  image
}

class Content extends ManagedObject<_Content> implements _Content {
  @Serialize()
  bool get isText => contentType == ContentType.text;
  @Serialize()
  bool get isImage => contentType == ContentType.image;

  @override
  void willUpdate() {
  }

  @override
  void willInsert() {
  }
}

class _Content {
  @primaryKey
  int id;
  int position;
  ContentType contentType;
  Document contentData;

  @Relate(#contents)
  Page page;
}