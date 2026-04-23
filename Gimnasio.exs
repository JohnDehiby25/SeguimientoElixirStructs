#Ejemplo 1: Sistema de Gimnasio (guía de structs) y su correspondiente persistencia (guía de manejo de archivos): Cargar datos al iniciar el programa y guardar automáticamente después de cada operación
defmodule Gimnasio do
  def main do
    # Inicializar desde archivo
    socios = cargar_datos()

    # Agregar socios
    {:ok, socios} = agregar_socio(socios, "123", "Juan Pérez", 30)
    {:ok, socios} = agregar_socio(socios, "456", "María García", 25)
    {:ok, socios} = agregar_socio(socios, "789", "Carlos López", 35)

    # Intentar agregar duplicado
    case agregar_socio(socios, "123", "Otro Juan", 28) do
      {:error, :cedula_duplicada} ->
        IO.puts("No se puede agregar: cédula duplicada")
      {:ok, _} ->
        IO.puts("Socio agregado")
    end

    # Inscribir en clases
    {:ok, socios} = inscribir_clase(socios, "123", "Yoga")
    {:ok, socios} = inscribir_clase(socios, "123", "Pilates")
    {:ok, socios} = inscribir_clase(socios, "456", "Spinning")

    # Intentar duplicado
    case inscribir_clase(socios, "123", "Yoga") do
      {:error, :ya_inscrito} ->
        IO.puts("Ya está inscrito en esa clase")
      {:ok, _} ->
        IO.puts("Inscrito en clase")
    end

    # Mostrar socio
    case obtener_socio(socios, "123") do
      {:ok, socio} ->
        IO.puts("\n=== Socio 123 ===")
        IO.inspect(socio)
      {:error, _} ->
        IO.puts("Socio no encontrado")
    end

    # Estadísticas
    IO.puts("\n=== Estadísticas ===")
    IO.inspect(obtener_estadisticas(socios))

    # Socios en Yoga
    IO.puts("\n=== Socios en Yoga ===")
    socios_en_clase(socios, "Yoga")
    |> Enum.each(&IO.puts(&1.nombre))

    # Actualizar
    {:ok, socios} = actualizar_socio(socios, "123", "Juan Pérez Gómez", 31)

    # Eliminar
    {:ok, socios} = eliminar_socio(socios, "789")

    # Mostrar todos
    IO.inspect(listar_socios(socios))
  end

  # ---------------- CRUD ----------------

  def agregar_socio(socios, cedula, nombre, edad) do
    case Socio.nuevo(nombre, edad) do
      {:ok, nuevo_socio} ->
        if Map.has_key?(socios, cedula) do
          {:error, :cedula_duplicada}
        else
          nuevos = Map.put(socios, cedula, nuevo_socio)
          guardar_datos(nuevos)
          {:ok, nuevos}
        end

      {:error, razon} ->
        {:error, razon}
    end
  end

  def obtener_socio(socios, cedula) do
    case Map.get(socios, cedula) do
      nil -> {:error, :no_encontrado}
      socio -> {:ok, socio}
    end
  end

  def actualizar_socio(socios, cedula, nombre, edad) do
    case Map.get(socios, cedula) do
      nil ->
        {:error, :no_encontrado}

      socio ->
        actualizado = %{socio | nombre: nombre, edad: edad}
        nuevos = Map.put(socios, cedula, actualizado)
        guardar_datos(nuevos)
        {:ok, nuevos}
    end
  end

  def eliminar_socio(socios, cedula) do
    if Map.has_key?(socios, cedula) do
      nuevos = Map.delete(socios, cedula)
      guardar_datos(nuevos)
      {:ok, nuevos}
    else
      {:error, :no_encontrado}
    end
  end

  def inscribir_clase(socios, cedula, clase) do
    case Map.get(socios, cedula) do
      nil ->
        {:error, :no_encontrado}

      socio ->
        case Socio.inscribir_clase(socio, clase) do
          {:ok, actualizado} ->
            nuevos = Map.put(socios, cedula, actualizado)
            guardar_datos(nuevos)
            {:ok, nuevos}

          {:error, razon} ->
            {:error, razon}
        end
    end
  end

  def desinscribir_clase(socios, cedula, clase) do
    case Map.get(socios, cedula) do
      nil ->
        {:error, :no_encontrado}

      socio ->
        {:ok, actualizado} = Socio.desinscribir_clase(socio, clase)
        nuevos = Map.put(socios, cedula, actualizado)
        guardar_datos(nuevos)
        {:ok, nuevos}
    end
  end

  # ---------------- UTILIDADES ----------------

  def listar_socios(socios), do: Map.values(socios)

  def socios_en_clase(socios, clase) do
    socios
    |> Map.values()
    |> Enum.filter(&Socio.tiene_clase?(&1, clase))
  end

  def obtener_estadisticas(socios) do
    %{
      total: map_size(socios),
      edad_promedio: calcular_edad_promedio(socios)
    }
  end

  defp calcular_edad_promedio(socios) when map_size(socios) == 0, do: 0
  defp calcular_edad_promedio(socios) do
    edades = socios |> Map.values() |> Enum.map(& &1.edad)
    Enum.sum(edades) / length(edades)
  end

  # ---------------- ARCHIVOS ----------------

  def cargar_datos do
    case File.read("socios.txt") do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn linea, acc ->
          [cedula, nombre, edad, clases_str] = String.split(linea, ";")

          clases =
            if clases_str == "" do
              []
            else
              String.split(clases_str, ",")
            end

          socio = %Socio{
            nombre: nombre,
            edad: String.to_integer(edad),
            clases: clases
          }

          Map.put(acc, cedula, socio)
        end)

      {:error, _} ->
        %{}
    end
  end

  def guardar_datos(socios) do
    contenido =
      socios
      |> Enum.map(fn {cedula, socio} ->
        clases = Enum.join(socio.clases, ",")
        "#{cedula};#{socio.nombre};#{socio.edad};#{clases}"
      end)
      |> Enum.join("\n")

    File.write("socios.txt", contenido)
  end
end


defmodule Socio do
  @enforce_keys [:nombre, :edad]
  defstruct [:nombre, :edad, clases: []]

  def nuevo(nombre, edad) when edad > 0 and edad < 100 do
    {:ok, %__MODULE__{nombre: nombre, edad: edad}}
  end

  def nuevo(_, _), do: {:error, :edad_invalida}

  def inscribir_clase(%__MODULE__{clases: clases} = socio, clase) do
    if clase in clases do
      {:error, :ya_inscrito}
    else
      {:ok, %{socio | clases: [clase | clases]}}
    end
  end

  def desinscribir_clase(%__MODULE__{clases: clases} = socio, clase) do
    {:ok, %{socio | clases: List.delete(clases, clase)}}
  end

  def tiene_clase?(%__MODULE__{clases: clases}, clase) do
    clase in clases
  end
end


Gimnasio.main()
