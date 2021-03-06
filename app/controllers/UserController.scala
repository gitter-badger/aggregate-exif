package controllers

import javax.inject.{Inject, Singleton}

import authes.AuthConfigImpl
import authes.Role.NormalUser
import com.github.tototoshi.play2.json4s.native.Json4s
import jp.t2v.lab.play2.auth.AuthElement
import models.User
import org.json4s.{DefaultFormats, Extraction}
import play.api.mvc._
import queries.CreateUser
import scalikejdbc._

@Singleton
class UserController @Inject()(json4s: Json4s) extends Controller with AuthElement with AuthConfigImpl {
  import json4s._
  import Responses._

  implicit def formats = DefaultFormats

  def show() = StackAction(AuthorityKey -> NormalUser) { implicit req =>
    Ok(Extraction.decompose(loggedIn.minimal))
  }

  def list(public: Boolean) = Action {
    import models.Aliases.u
    val users = if(public) User.findAllBy(sqls.eq(u.public, true))
    else User.findAll()
    Ok(Extraction.decompose(users.map(_.minimal)))
  }

  def showMin(id: Long) = Action {
    User.findById(id).fold(notFound("player")) { user =>
      Ok(Extraction.decompose(user.minimal))
    }
  }

  def createAccount() = Action(json) { req =>
    req.body.extractOpt[CreateUser].fold(JsonParseError) { user =>
      User.create(user.user())(AutoSession)
      Success
    }
  }

  def public(next: Boolean) = StackAction(AuthorityKey -> NormalUser) { implicit req =>
    val result = User.updateById(loggedIn.id).withAttributes('public -> next)(AutoSession)
    if(result > 0) Success else InternalServerError
  }
}
