object LeveleadorDeHeroes{
  def subirNivel(heroe: Heroe): Heroe = {
    val nuevaEstadistica: Estadistica = new Estadistica(heroe.estadistica.fuerza, heroe.estadistica.velocidad, heroe.estadistica.nivel+1, heroe.estadistica.salud)
    heroe.trabajo match {
      case Guerrero => heroe.copy(trabajo = heroe.trabajo, nuevaEstadistica)

    }
  }
}

case class Heroe(val trabajo: Trabajo, val estadistica: Estadistica){
}

sealed trait Trabajo{

}

class Estadistica(val fuerza: Int, var velocidad: Int, var nivel: Int, var salud: Int)

//case class Guerrero(estadistica: Estadistica = estadistica.) extends Trabajo {}
case object Guerrero extends Trabajo {

}
case class Mago() extends Trabajo {

}

case class Ladron() extends Trabajo{

}