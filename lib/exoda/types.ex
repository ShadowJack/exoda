defmodule Exoda.Types do
  require Logger

  @moduledoc """
  Module contains a part of implementation of `Ecto.Adapter` behaviour
  related to types convertion.
  """

  @doc """
  Returns the loaders for a given type.

  Is used to trasform types returned from http endpoint
  to ecto types

  It receives the primitive type and the Ecto type (which may be
  primitive as well). It returns a list of loaders with the given
  type at the end.

  """
  @spec loaders(primitive_type :: Ecto.Type.primitive(), ecto_type :: Ecto.Type.t()) :: [
          (term -> {:ok, term} | :error) | Ecto.Type.t()
        ]
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(:utc_datetime, type), do: [&datetime_decode/1, type]
  def loaders(_primitive, type), do: [type]

  defp datetime_decode(datetime) do
    erl_datetime = NaiveDateTime.from_iso8601!(datetime) |> NaiveDateTime.to_erl()
    {:ok, erl_datetime}
  end

  @doc """
  Returns the dumpers for a given type.

  It receives the primitive type and the Ecto type (which may be
  primitive as well). It returns a list of dumpers with the given
  type at the beginning.

  It is used to translate values coming from the Ecto into a http compliant types
  """
  @spec dumpers(primitive_type :: Ecto.Type.primitive(), ecto_type :: Ecto.Type.t()) :: [
          (term -> {:ok, term} | :error) | Ecto.Type.t()
        ]
  def dumpers(:binary_id, type), do: [type, Ecto.UUID]
  def dumpers(:utc_datetime, type), do: [type, &datetime_encode/1]
  def dumpers(_primitive, type), do: [type]

  defp datetime_encode({{year, month, day}, {hour, minute, second, microsecond}}) do
    datetime =
      NaiveDateTime.from_erl!({{year, month, day}, {hour, minute, second}}, {microsecond, 6})
      |> NaiveDateTime.to_iso8601()

    {:ok, "#{datetime}Z"}
  end

  #
  ## Autogenerate

  @doc """
  Called to autogenerate a value for id/embed_id/binary_id.

  Returns nil when id must be autogenerated inside the storage.
  """
  @spec autogenerate(field_type :: :id | :binary_id | :embed_id) :: term | nil | no_return
  def autogenerate(:id), do: nil
  def autogenerate(:embed_id), do: Ecto.UUID.generate()
  def autogenerate(:binary_id), do: Ecto.UUID.autogenerate()
end
