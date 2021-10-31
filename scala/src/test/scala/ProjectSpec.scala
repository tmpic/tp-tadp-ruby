import org.scalatest.matchers.should.Matchers._
import org.scalatest.freespec.{AnyFreeSpec}

class ProjectSpec extends AnyFreeSpec {

  "Este proyecto" - {

    "cuando está correctamente configurado" - {
      "debería resolver las dependencias y pasar este test" in {
        Prueba.materia shouldBe "tadp"
      }
    }
    "heroes" - {
      "si le subo un nivel a un guerrero deberia de aumentar en 1" in {
        val estadistica = new Estadistica(10,10,10,10)
        val trabajo = Guerrero()
        val guerrero = Heroe(trabajo, estadistica)

        val nuevoGuerrero = LeveleadorDeHeroes.subirNivel(guerrero)

        nuevoGuerrero.estadistica.nivel shouldBe 11


      }
    }
  }

}
