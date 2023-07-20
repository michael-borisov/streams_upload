defmodule StreamsUpload.Block do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blocks" do
    field(:type, Ecto.Enum, values: [:text, :photo])
    field(:block_id, :integer, virtual: true)
    field(:position, :integer)
    field(:data, :map)
  end

  def block_changeset(block, attrs) do
    block
    |> cast(attrs, [:type, :position, :data])
  end
end
