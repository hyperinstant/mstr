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

    # |> validate_tracks()
  end

  def validate_track(field, track_url) do
    if SSpotify.valid_track_url?(track_url) do
      []
    else
      Keyword.put([], field, "link is not recognised")
    end
  end

  # defp validate_tracks(changeset) do
  #   if changeset.valid? do
  #     profile = apply_changes(changeset)

  #     profile
  #     |> verify_spotify_tracks()
  #     |> Enum.reduce(changeset, fn {field, error}, acc ->
  #       add_error(acc, field, error)
  #     end)
  #   else
  #     changeset
  #   end
  # end

  # defp verify_spotify_tracks(profile) do
  #   tracks = [profile.track_1, profile.track_2, profile.track_3]

  #   case SSpotify.tracks_from(tracks) do
  #     {:ok, _tracks} ->
  #       []

  #     {:error, %SSpotify.Errors.InvalidTrackUrl{url: url}} ->
  #       # Find which field contains the invalid URL and add the error
  #       field =
  #         cond do
  #           profile.track_1 == url -> :track_1
  #           profile.track_2 == url -> :track_2
  #           profile.track_3 == url -> :track_3
  #         end

  #       [{field, "link is not recognised"}]
  #   end
  # end
end
