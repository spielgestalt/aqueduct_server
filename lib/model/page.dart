import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_server/aqueduct_server.dart';
import '../model/content.dart';

enum PageStatus {
  published,
  review

}

class Page extends ManagedObject<_Page> implements _Page {
  @override
  void willUpdate() {
  }

  @override
  void willInsert() {
  }
}

class _Page {
  @primaryKey
  int id;

  @Column(indexed: true, defaultValue: "false")
  bool isRoot;
  PageStatus pageStatus;

  @Column(unique: true, indexed: true)
  String title;

  @Column(unique: true, indexed: true)
  String slug;
  ManagedSet<Content> contents;
}