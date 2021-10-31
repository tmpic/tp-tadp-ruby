/*
/*
trait Heroe2{
  def subirNivel(): Heroe = {new Heroe(nuevaEstadistica)}
}

abstract class Heroe(val estadistica: Estadistica) {
  def subirNivel(): Heroe = {
    val nuevaEstadistica: Estadistica = new Estadistica(estadistica.fuerza, estadistica.velocidad, estadistica.nivel+1, estadistica.salud)
    new Heroe(nuevaEstadistica)
  }
}



class Guerrero(_fuerza: Int, velocidad: Int, nivel: Int, salud: Int) extends Heroe(_fuerza, velocidad, nivel, salud){
  override def fuerza: Int = (_fuerza + nivel * 1.2).round.asInstanceOf[Int]
}
*/

class Estadistica(val fuerza: Int, var velocidad: Int, var nivel: Int, var salud: Int)

trait Trabajo{
}

class Heroe(val trabajo: Trabajo, val estadistica: Estadistica){

}

case class Guerrero(val estadistica: Estadistica) extends Trabajo {
  def subirNivel(): Guerrero = {
    val nuevaEstadistica: Estadistica = new Estadistica(estadistica.fuerza, estadistica.velocidad, estadistica.nivel+1, estadistica.salud)
    new Guerrero(nuevaEstadistica)
  }
}


def subirNivel(heroe: Heroe): Heroe = {
  heroe match {
    case Guerrero =>
      new Guerrero(null)

  }
}

/*
class Ladron(_fuerza: Int, _velocidad: Int, _nivel: Int, _salud: Int, _habilidad: Int) extends Heroe(_fuerza, _velocidad, _nivel, _salud){
  var habilidad: Int = _habilidad

  override def subirNivel(): Unit = {
    super.subirNivel()
    habilidad = habilidad + 3
  }
}

class Mago(_fuerza: Int, _velocidad: Int, _nivel: Int, _salud: Int, _hechizos_a_aprender: Set[(Hechizo, Int)]) extends Heroe(_fuerza, _velocidad, _nivel, _salud){
  var hechizos_a_aprender: Set[(Hechizo, Int)] = _hechizos_a_aprender
  //var hechizos_aprendidos: Set[Hechizo] = Set.empty[Hechizo]TODO hacer calculable con un metodo los hechizos con un filter

  def aprenderHechizo(hechizo: Hechizo): Unit = {
    //hechizos_aprendidos += hechizo
  }

  def puedeAprenderHechizo(hechizo: (Hechizo, Int)) = {
    if(hechizo._2 == nivel) {
      aprenderHechizo(hechizo._1)
    }
  }
}

class Hechizo(_nombre: String){
  var hechizos: String = _nombre
}

class Golondrina{
  def volar(): String = "volar"

  def cantar(): String = "pio"
}

class Gaviota{
  def volar(): String = "otroVolar"

  def cantar(): String = "otroPio"
}
class Pajaro{
  def volar(): String = "otroVolar"

  def cantar(): String = "otroPio"
}
class Ave{

}

case object GolondrinaFuncional extends Ave

case object GaviotaFuncional extends Ave

case object Pajaro extends Ave

def volar(ave: Ave) : String = ave match{
  case GolondrinaFuncional => "volar"
  case GaviotaFuncional => "otroVolar"
  case Pajaro => "otroVolar"
}

def cantar(ave: Ave) : String = ave match{
  case GolondrinaFuncional => "pio"
  case GaviotaFuncional => "otroPio"
  case Pajaro => "otroPio"
}*/
*/