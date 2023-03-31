import 'package:conduit/conduit.dart';
import 'package:pr_api/model/post.dart';
import 'package:conduit_core/conduit_core.dart';

class Author extends ManagedObject<_Author> implements _Author {}

class _Author {
  @primaryKey
  int? id;

  ManagedSet<Post>? postList;
}
