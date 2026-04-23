#Implementar un struct Producto con los campos codigo, nombre, precio y cantidad. Luego, crear un módulo Inventario que permita agregar, actualizar, eliminar y listar productos en un inventario. Utilizar un mapa para almacenar los productos, donde la clave sea el código del producto.
defmodule Producto do
  @enforce_keys [:codigo, :nombre, :precio, :cantidad]
  defstruct [:codigo, :nombre, :precio, :cantidad]

  def nuevo(codigo, nombre, precio, cantidad) do
    cond do
      String.length(codigo) > 5 ->
        {:error, :codigo_largo}

      precio < 0 ->
        {:error, :precio_invalido}

      cantidad < 0 ->
        {:error, :cantidad_invalida}

      not is_integer(cantidad) ->
        {:error, :cantidad_no_entera}

      true ->
        {:ok, %__MODULE__{
          codigo: codigo,
          nombre: nombre,
          precio: precio,
          cantidad: cantidad
        }}
    end
  end
end

defmodule Inventario do
  # ---------------- CRUD ----------------
  def agregar_producto(inv, codigo, nombre, precio, cantidad) do
    if Map.has_key?(inv, codigo) do
      {:error, :codigo_repetido}
    else
      case Producto.nuevo(codigo, nombre, precio, cantidad) do
        {:ok, producto} ->
          {:ok, Map.put(inv, codigo, producto)}

        {:error, razon} ->
          {:error, razon}
      end
    end
  end

  def actualizar_producto(inv, codigo, nombre, precio, cantidad) do
    if Map.has_key?(inv, codigo) do
      case Producto.nuevo(codigo, nombre, precio, cantidad) do
        {:ok, producto} ->
          {:ok, Map.put(inv, codigo, producto)}

        {:error, razon} ->
          {:error, razon}
      end
    else
      {:error, :no_encontrado}
    end
  end

  def eliminar_producto(inv, codigo) do
    if Map.has_key?(inv, codigo) do
      {:ok, Map.delete(inv, codigo)}
    else
      {:error, :no_encontrado}
    end
  end

  def listar(inv), do: Map.values(inv)

  # ---------------- REPORTES ----------------

  # 1. Nombre con al menos 2 vocales
  def nombres_con_dos_vocales(inv) do
    inv
    |> Map.values()
    |> Enum.filter(fn p ->
      p.nombre
      |> String.downcase()
      |> String.graphemes()
      |> Enum.count(&(&1 in ["a","e","i","o","u"])) >= 2
    end)
    |> Enum.map(fn p -> {p.codigo, p.nombre} end)
  end

  # 2. Empieza y termina con misma letra
  def mismo_inicio_fin(inv) do
    inv
    |> Map.values()
    |> Enum.filter(fn p ->
      nombre = String.downcase(p.nombre)
      String.first(nombre) == String.last(nombre)
    end)
  end

  # 3. Productos por debajo de cierto precio
  def por_debajo_precio(inv, precio) do
    inv
    |> Map.values()
    |> Enum.filter(&(&1.precio < precio))
  end

  # 4. Tres más caros
  def tres_mas_caros(inv) do
    inv
    |> Map.values()
    |> Enum.sort_by(& &1.precio, :desc)
    |> Enum.take(3)
  end

  # 5. Cadena entre dos precios
  def cadena_entre_precios(inv, min, max) do
    inv
    |> Map.values()
    |> Enum.filter(&(&1.precio >= min and &1.precio <= max))
    |> Enum.map(fn p -> "#{p.nombre}:#{p.precio}" end)
    |> Enum.join(", ")
  end

  # 6. Agrupar por rango de precio
  def agrupar_por_precio(inv) do
    Enum.reduce(Map.values(inv), %{
      menores_50k: [],
      entre_50k_100k: [],
      mayores_100k: []
    }, fn p, acc ->
      cond do
        p.precio < 50000 ->
          Map.update!(acc, :menores_50k, &[p | &1])

        p.precio <= 100000 ->
          Map.update!(acc, :entre_50k_100k, &[p | &1])

        true ->
          Map.update!(acc, :mayores_100k, &[p | &1])
      end
    end)
  end
end

defmodule InventarioProductos do
  def main do
    inv = %{}

    {:ok, inv} = Inventario.agregar_producto(inv, "A1", "Arroz", 30000, 10)
    {:ok, inv} = Inventario.agregar_producto(inv, "B2", "Aceite", 70000, 5)
    {:ok, inv} = Inventario.agregar_producto(inv, "C3", "Azucar", 120000, 8)
    {:ok, inv} = Inventario.agregar_producto(inv, "D4", "Uva", 20000, 15)

    IO.puts("\nDos vocales:")
    IO.inspect(Inventario.nombres_con_dos_vocales(inv))

    IO.puts("\nMismo inicio y fin:")
    IO.inspect(Inventario.mismo_inicio_fin(inv))

    IO.puts("\nMenores a 50000:")
    IO.inspect(Inventario.por_debajo_precio(inv, 50000))

    IO.puts("\nTres más caros:")
    IO.inspect(Inventario.tres_mas_caros(inv))

    IO.puts("\nCadena entre precios:")
    IO.puts(Inventario.cadena_entre_precios(inv, 20000, 80000))

    IO.puts("\nAgrupados:")
    IO.inspect(Inventario.agrupar_por_precio(inv))
  end
end

InventarioProductos.main()
