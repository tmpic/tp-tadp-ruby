require 'rspec'
require_relative '../lib/aspects'

describe 'tp ruby' do
  it 'Se debe de poder definir un aspecto para un objeto' do
    class Pepito
      def foo
      end
      def bar
      end
    end
    miObjeto = Pepito.new
    metodos = Aspects.on miObjeto do
      where name(/foo/)

    end
    expect(metodos).to eq [:foo]
  end

  it 'El framework no debe permitir la definición de un Origen vacío' do
    expect{Aspects.on}.to raise_error(ArgumentError, "wrong number of arguments (0 for +1)")
  end

  it 'El framework debe lanzar una excepcion ante la no existencia de un origen' do
    expect{Aspects.on /NombreDeClaseQueNoExiste/ do end }.to raise_error(ArgumentError, "origen vacío? el origen no existe")
  end

  it 'where me tiene que devolver los metodos que cumplen la condicion' do
    class Roberto
      def foo
      end
      def bar
      end
    end
    metodos = Aspects.on /Roberto/ do
      where name(/foo/)

    end

    expect(metodos).to eq [:foo]
  end

  it 'probando has_parameters' do
    class MiClase2
      def foo(p1, p2, p3, p4='a', p5='b', p6='c')
      end
      def bar(p1, p2='a', p3='b', p4='c')
      end
    end

    metodos = Aspects.on MiClase2 do
      where has_parameters(3, mandatory)
      #where has_parameters(6)
      # array con el método foo
    end

    expect(metodos).to eq [:foo]
  end

  it 'probando has_parameters2' do
    class MiClase3
      def foo(p1, p2, p3, p4='a', p5='b', p6='c')
      end
      def bar(p1, p2='a', p3='b', p4='c')
      end
    end

    metodos = Aspects.on MiClase3 do
      where has_parameters(3, optional)
      # array con los métodos foo y bar
    end

    expect(metodos).to match_array [:foo, :bar]
  end

  it 'probando has_parameters3' do
    class MiClase4
      def foo(param1, param2)
      end

      def bar(param1)
      end


    end

    metodos = Aspects.on MiClase4 do
      where has_parameters(1, /param.*/)
      # array con el método bar
    end
    metodos2 = Aspects.on MiClase4 do
      where has_parameters(2, /param.*/)
      # array con el método bar
    end
    expect(metodos).to eq [:bar]
    expect(metodos2).to eq [:foo]
  end

  it 'Negación Esta condición recibe otras condiciones por parámetro y se cumple cuando ninguna de ellas se cumple.' do
    class MiClase5
      def foo1(p1)
      end
      def foo2(p1, p2)
      end
      def foo3(p1, p2, p3)
      end
    end

    metodos = Aspects.on MiClase5 do
      where name(/foo\d/), neg(has_parameters(1))
      # array con los métodos foo2 y foo3
    end
    expect(metodos).to match_array [:foo2, :foo3]
  end

  it 'Transformacion con inyeccion de parametro' do
    class MiClase6
      def hace_algo(p1, p2)
        p1 + '-' + p2
      end
    end

    metodos = Aspects.on MiClase6 do
      transform(where has_parameters(2, /p.*/)) do
        inject(p2: 'bar')
      end
    end

    instancia = MiClase6.new
    expect(instancia.hace_algo("foo")).to eq "foo-bar"
    # "foo-bar"
    # expect(metodos).to eq [:hace_algo]

  end

  it 'Transformacion con Redirección de objeto sustituto por parámetro' do
    class A
      def saludar(x)
        "Hola, " + x
      end
    end

    class C
      def saludar(x)
        "Hola, " + x
      end
    end

    class B
      def saludar(x)
        "Adiosín, " + x
      end
    end

    Aspects.on A do
      transform(where name(/saludar/)) do
        redirect_to(B.new)
      end
    end

    respuesta_instancia_A = A.new.saludar("Mundo")
    # respuesta_instancia_C = C.new.saludar("Mundo")
    expect(respuesta_instancia_A).to eq "Adiosín, Mundo"
    # expect(respuesta_instancia_C).to eq "Adiosín, Mundo"
    #"Adiosín, Mundo"

  end

  it 'Inyeccion de logica' do
    class MiClase
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClase do
      transform(where name(/m1/)) do
        before do |instance, cont, *args|

          @x = 10
          new_args = args.map{ |arg| arg * 10 }
          cont.call(*new_args)

        end
      end
    end

    instancia = MiClase.new
    expect(instancia.m1(1, 2)).to eq 30


  end

  it 'Inyeccion de logica2' do
    class MiClase
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClase do
      transform(where name(/m3/)) do
        instead_of do |instance, *args|
          @x = 123
        end
      end
    end

    instancia = MiClase.new
    expect(instancia.m3(48)).to eq 123
  end

  it 'Inyeccion de logica3' do
    class MiClasarda
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClasarda do
      transform(where name(/m3/)) do
        instead_of do |instance, *args|
          args
        end
      end
    end

    instancia = MiClasarda.new
    expect(instancia.m3(1, 2, 3)).to eq [1, 2, 3]
  end

  it 'after' do
    class MiClasarda2
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClasarda2 do
      transform(where name(/m2/)) do
        after do |instance, *args|
          if @x > 100
            2 * @x
          else
            @x
          end
        end
      end
    end

    instancia = MiClasarda2.new
    expect(instancia.m2(10)).to eq 10
  end

  it 'debe ser posible aplicar transformaciones sucesivas' do
    class A
      def saludar(x)
        "Hola, " + x
      end
    end

    class B
      def saludar(x)
        "Adiosín, " + x
      end
    end

    Aspects.on A do
      transform(where name(/saludar/)) do
        inject(x: "Tarola")
        redirect_to(B.new)
      end
    end

    resultado = A.new.saludar("Mundo")
    expect(resultado).to eq "Adiosín, Tarola"
    # "Hola, Tarola"

  end

  it 'Custom' do
    class MiClaseCustom
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClaseCustom do
      transform(where name(/m3/)) do
        instead_of do |instance, *args|
          @x = 123
        end
        inject(x: 55)
      end
    end

    instancia = MiClaseCustom.new
    expect(instancia.m3(48)).to eq 123
  end

  it 'after Custom' do
    class BCustom
      def m2(x)
        x + 10
      end
    end
    class MiClasaAfterCustom
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClasaAfterCustom do
      transform(where name(/m2/)) do
        after do |instance, *args|
          if @x > 100
            2 * @x
          else
            @x
          end
        end
        redirect_to(BCustom.new)
      end
    end

    instancia = MiClasaAfterCustom.new
    expect(instancia.m2(10)).to eq 20
  end

  it 'before Custom' do
    class MiClaseBeforeCustom
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClaseBeforeCustom do
      transform(where name(/m1/)) do

        before do |instance, cont, *args|
          @x = 10
          new_args = args.map{ |arg| arg * 10 }
          cont.call(*new_args)
        end
        inject(x: 2)
      end
    end

    instancia = MiClaseBeforeCustom.new
    expect(instancia.m1(1, 2)).to eq 40
  end

  it 'inject con proc' do
    class MiClaseConProc
      def hace_algo(p1, p2)
        p1 + "-" + p2
      end
    end

    Aspects.on MiClaseConProc do
      transform(where has_parameters(1, /p2/)) do
        inject(p2: proc{ |receptor, mensaje, arg_anterior|
          "bar(#{mensaje}->#{arg_anterior})"
        })
      end
    end

    resultado = MiClaseConProc.new.hace_algo('foo', 'foo')
    expect(resultado).to eq 'foo-bar(hace_algo->foo)'
  end

  it 'Verificando que se ordenan las transformaciones' do
    class Ordenando
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on Ordenando do
      transform(where name(/m3/)) do
        inject(x: 55)
        instead_of do |instance, *args|
          @x = 123
        end
      end
    end

    instancia = Ordenando.new
    expect(instancia.m3(48)).to eq 123
  end
  it 'is_public tp individual' do
    class MiClaseIs_public
      def foo
      end

      private

      def bar
      end
    end

    resultado = Aspects.on MiClaseIs_public do
      where name(/bar/), is_public
      # array vacío
    end
    expect(resultado).to eq []
  end

  it 'is_private tp individual' do
    class MiClaseIs_private
      def foo
      end

      private

      def bar
      end
    end

    resultado2 = Aspects.on MiClaseIs_private do
      where name(/bar/), is_private
      # array con el método bar
    end
    expect(resultado2).to eq [:bar]
  end

  it 'solo los publicos debe traer is_public tp individual' do
    class MiClaseIs_public2
      def foo
      end

      private

      def bar
      end
    end

    resultado2 = Aspects.on MiClaseIs_public2 do
      where name(/foo/), is_private
      # array con el método bar
    end
    expect(resultado2).to eq []
  end

  it 'solo los privados debe traer is_private tp individual' do
    class MiClaseIs_public2
      def foo
      end

      private

      def bar
      end
    end

    resultado2 = Aspects.on MiClaseIs_public2 do
      where name(/foo/), is_private
      # array con el método bar
    end
    expect(resultado2).to eq []
  end
end
