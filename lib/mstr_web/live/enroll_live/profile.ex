defmodule MstrWeb.EnrollLive.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias SSpotify
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :nick, :string
    field :track_1, :string
    field :track_2, :string
    field :track_3, :string
    field :email, :string
  end

  def change(%Profile{} = profile, attrs \\ %{}) do
    changeset(profile, attrs)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:nick, :track_1, :track_2, :track_3, :email])
    |> validate_required([:nick, :track_1, :track_2, :track_3, :email])
    |> validate_change(:track_1, &validate_track/2)
    |> validate_change(:track_2, &validate_track/2)
    |> validate_change(:track_3, &validate_track/2)
  end

  def validate_track(field, track_url) do
    if SSpotify.valid_track_url?(track_url) do
      []
    else
      Keyword.put([], field, "link is not recognised")
    end
  end
end
