package syntax.tests

import scala.concurrent.{ExecutionContext, Future}

@deprecated("legacy API", "1.0")
trait Service {
  def fetch(id: Long): Future[String]
}

enum Level {
  case Debug, Info, Warn, Error
}

case class User(id: Long, name: String)

object Repository {
  private val Prefix = "user"
  private val defaultUser: User = User(0L, "guest")

  def format(user: User): String = {
    val score = 42
    val pi = 3.14
    s"$Prefix:${user.id}:${user.name}:$score:$pi"
  }

  def find(id: Long)(using ec: ExecutionContext): Future[User] = {
    if (id <= 0) then
      Future.successful(defaultUser)
    else
      Future.successful(User(id, s"name-$id"))
  }

  extension (user: User)
    def greeting: String =
      s"Hello, ${user.name}!"
}

class ServiceImpl extends Service {
  override def fetch(id: Long): Future[String] = {
    val result = Repository.find(id).map(Repository.format)
    result
  }
}

// line comment
/* block comment */
