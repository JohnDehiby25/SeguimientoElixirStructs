defmodule Libro do
  @enforce_keys [:isbn, :titulo, :autor]
  defstruct [:isbn, :titulo, :autor, :año, :genero, disponible: true]

  def prestar(%__MODULE__{disponible: false}), do: {:error, :no_disponible}
  def prestar(libro), do: {:ok, %{libro | disponible: false}}

  def devolver(libro), do: {:ok, %{libro | disponible: true}}

  def es_clasico?(%__MODULE__{año: año}) do
    año != nil and Date.utc_today().year - año > 50
  end
end

defmodule Usuario do
  @enforce_keys [:id, :nombre, :email]
  defstruct [:id, :nombre, :email, libros_prestados: []]

  def puede_prestar?(%__MODULE__{libros_prestados: libros}) do
    length(libros) < 3
  end

  def agregar_prestamo(usuario, isbn) do
    {:ok, %{usuario | libros_prestados: [isbn | usuario.libros_prestados]}}
  end

  def quitar_prestamo(usuario, isbn) do
    {:ok, %{usuario | libros_prestados: List.delete(usuario.libros_prestados, isbn)}}
  end
end


defmodule Prestamo do
  @enforce_keys [:id, :libro_isbn, :usuario_id, :fecha_prestamo]
  defstruct [:id, :libro_isbn, :usuario_id, :fecha_prestamo, fecha_devolucion: nil]

  def devolver(prestamo) do
    {:ok, %{prestamo | fecha_devolucion: Date.utc_today()}}
  end

  def dias_retraso(%__MODULE__{fecha_prestamo: f, fecha_devolucion: nil}) do
    dias = Date.diff(Date.utc_today(), f)
    max(dias - 7, 0)
  end

  def dias_retraso(%__MODULE__{fecha_prestamo: f, fecha_devolucion: d}) do
    dias = Date.diff(d, f)
    max(dias - 7, 0)
  end
end


defmodule Biblioteca do
  # Estado: %{libros: %{}, usuarios: %{}, prestamos: %{}}

  def nueva do
    %{libros: %{}, usuarios: %{}, prestamos: %{}}
  end

  # -------- LIBROS --------

  def agregar_libro(bib, libro) do
    if Map.has_key?(bib.libros, libro.isbn) do
      {:error, :isbn_duplicado}
    else
      {:ok, %{bib | libros: Map.put(bib.libros, libro.isbn, libro)}}
    end
  end

  # -------- USUARIOS --------

  def agregar_usuario(bib, usuario) do
    {:ok, %{bib | usuarios: Map.put(bib.usuarios, usuario.id, usuario)}}
  end

  # -------- PRESTAR --------

  def prestar_libro(bib, isbn, user_id, prestamo_id) do
    with libro when not is_nil(libro) <- Map.get(bib.libros, isbn),
         usuario when not is_nil(usuario) <- Map.get(bib.usuarios, user_id),
         true <- Usuario.puede_prestar?(usuario),
         {:ok, libro_act} <- Libro.prestar(libro),
         {:ok, usuario_act} <- Usuario.agregar_prestamo(usuario, isbn) do

      prestamo = %Prestamo{
        id: prestamo_id,
        libro_isbn: isbn,
        usuario_id: user_id,
        fecha_prestamo: Date.utc_today()
      }

      {:ok, %{
        bib |
        libros: Map.put(bib.libros, isbn, libro_act),
        usuarios: Map.put(bib.usuarios, user_id, usuario_act),
        prestamos: Map.put(bib.prestamos, prestamo_id, prestamo)
      }}
    else
      false -> {:error, :limite_libros}
      {:error, r} -> {:error, r}
      _ -> {:error, :no_encontrado}
    end
  end

  # -------- DEVOLVER --------

  def devolver_libro(bib, prestamo_id) do
    case Map.get(bib.prestamos, prestamo_id) do
      nil ->
        {:error, :no_encontrado}

      prestamo ->
        {:ok, prestamo} = Prestamo.devolver(prestamo)

        libro = Map.get(bib.libros, prestamo.libro_isbn)
        {:ok, libro} = Libro.devolver(libro)

        usuario = Map.get(bib.usuarios, prestamo.usuario_id)
        {:ok, usuario} = Usuario.quitar_prestamo(usuario, prestamo.libro_isbn)

        {:ok, %{
          bib |
          libros: Map.put(bib.libros, libro.isbn, libro),
          usuarios: Map.put(bib.usuarios, usuario.id, usuario),
          prestamos: Map.put(bib.prestamos, prestamo_id, prestamo)
        }}
    end
  end

  # -------- REPORTES --------

  def libros_mas_prestados(bib) do
    bib.prestamos
    |> Map.values()
    |> Enum.frequencies_by(& &1.libro_isbn)
  end

  def usuarios_con_retraso(bib) do
    bib.prestamos
    |> Map.values()
    |> Enum.filter(&(Prestamo.dias_retraso(&1) > 0))
    |> Enum.map(& &1.usuario_id)
    |> Enum.uniq()
  end

  def libros_por_genero(bib) do
    bib.libros
    |> Map.values()
    |> Enum.group_by(& &1.genero)
  end

  def disponibilidad(bib) do
    bib.libros
    |> Map.values()
    |> Enum.group_by(& &1.disponible)
  end
end


# -------- MAIN DE PRUEBA --------

defmodule GestionBiblioteca do
  def main do
    bib = Biblioteca.nueva()

    libro1 = %Libro{isbn: "1", titulo: "El Quijote", autor: "Cervantes", año: 1605, genero: "Novela"}
    libro2 = %Libro{isbn: "2", titulo: "1984", autor: "Orwell", año: 1949, genero: "Distopía"}

    usuario = %Usuario{id: "U1", nombre: "Juan", email: "juan@mail.com"}

    {:ok, bib} = Biblioteca.agregar_libro(bib, libro1)
    {:ok, bib} = Biblioteca.agregar_libro(bib, libro2)
    {:ok, bib} = Biblioteca.agregar_usuario(bib, usuario)

    {:ok, bib} = Biblioteca.prestar_libro(bib, "1", "U1", "P1")

    IO.puts("\nLibros más prestados:")
    IO.inspect(Biblioteca.libros_mas_prestados(bib))

    IO.puts("\nDisponibilidad:")
    IO.inspect(Biblioteca.disponibilidad(bib))
  end
end

GestionBiblioteca.main()
