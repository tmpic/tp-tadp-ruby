class Grupo{
  var integrantes: Set[Heroe] = Set.empty[Heroe]//TODO recordar que esta lista debe de estar jerarquizada
  var cofreComun: Cofre = new Cofre
  var puertas_encontradas_sin_abrir: Set[Puerta] = Set.empty[Puerta]
  var puertas_encontradas_abiertas: Set[Puerta] = Set.empty[Puerta]

  def repartirGanancias(){}//TODO

  def verificarHeroesCaidos(){}//TODO

  def puedeAbrir(puerta: Puerta){}//TODO

  def estadoGrupo(){} //TODO Informar el estado de un grupo tras visitar una habitación.
}

class Item(val nombre: String){}

class Cofre{
  var items: List[Item] = List.empty[Item]
}