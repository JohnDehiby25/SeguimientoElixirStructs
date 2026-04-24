#Ejemplo 1: Sistema de Gimnasio (guía de structs) y su correspondiente persistencia (guía de manejo de archivos): Cargar datos al iniciar el programa y guardar automáticamente después de cada operación
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

defmodule Gimnasio do
  def main do
    # 🔹 Cargar datos desde archivo
    socios = cargar_datos()

    # 🔹 Crear socios (usar cédulas que no estén en el archivo)
    {:ok, socios} = agregar_socio(socios, "100", "Juan Pérez", 30)
    {:ok, socios} = agregar_socio(socios, "200", "María García", 25)
    {:ok, socios} = agregar_socio(socios, "300", "Carlos López", 35)

    # 🔹 Inscribir en clases
    {:ok, socios} = inscribir_clase(socios, "100", "Yoga")
    {:ok, socios} = inscribir_clase(socios, "100", "Pilates")
    {:ok, socios} = inscribir_clase(socios, "200", "Spinning")

    # 🔹 Buscar socio
    {:ok, socio} = obtener_socio(socios, "100")
    IO.puts("\n=== Socio encontrado ===")
    IO.inspect(socio)

    # 🔹 Actualizar socio
    {:ok, socios} = actualizar_socio(socios, "100", "Juan Pérez Gómez", 31)

    # 🔹 Desinscribir clase
    {:ok, socios} = desinscribir_clase(socios, "100", "Yoga")

    # 🔹 Eliminar socio
    {:ok, socios} = eliminar_socio(socios, "300")

    # 🔹 Listar todos
    IO.puts("\n=== Lista de socios ===")
    IO.inspect(listar_socios(socios))
  end

  # ---------------- CRUD ----------------

  def agregar_socio(socios, cedula, nombre, edad) do
    case Socio.nuevo(nombre, edad) do
      {:ok, socio} ->
        if Map.has_key?(socios, cedula) do
          {:error, :cedula_duplicada}
        else
          nuevos = Map.put(socios, cedula, socio)
          guardar_datos(nuevos)
          {:ok, nuevos}
        end

      error -> error
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

          error -> error
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

  def obtener_socio(socios, cedula) do
    case Map.get(socios, cedula) do
      nil -> {:error, :no_encontrado}
      socio -> {:ok, socio}
    end
  end

  def listar_socios(socios), do: Map.values(socios)

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

Gimnasio.main()
