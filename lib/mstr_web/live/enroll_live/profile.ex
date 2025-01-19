defmodule MstrWeb.EnrollLive.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias SSpotify
  # alias SSpotify.Errors.InvalidTrackURLs
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :nick, :string
    field :track_url_1, :string
    field :track_url_2, :string
    field :track_url_3, :string
    field :email, :string

    # virtual fields to store validation state
    field :track_url_1_not_found, :boolean, virtual: true
    field :track_url_2_not_found, :boolean, virtual: true
    field :track_url_3_not_found, :boolean, virtual: true
  end

  def change(%Profile{} = profile, attrs \\ %{}) do
    changeset(profile, attrs)
  end

  def resolve(%Profile{} = profile, attrs \\ %{}) do
    changeset = changeset(profile, attrs)

    if changeset.valid? do
      case resolve_tracks(changeset) do
        {:ok, %{missing: [], found: tracks}} ->
          {:ok,
           %{
             email: fetch_change!(changeset, :email),
             nick: fetch_change!(changeset, :nick),
             track_1: find_track!(tracks, fetch_change!(changeset, :track_url_1)),
             track_2: find_track!(tracks, fetch_change!(changeset, :track_url_2)),
             track_3: find_track!(tracks, fetch_change!(changeset, :track_url_3))
           }}

        {:ok, %{missing: missing_track_urls}} ->
          changeset =
            Enum.reduce(missing_track_urls, changeset, &mark_field_as_missing/2)

          {:error, changeset}
      end
    else
      {:error, changeset}
    end
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:nick, :track_url_1, :track_url_2, :track_url_3, :email])
    |> validate_required([:nick, :track_url_1, :track_url_2, :track_url_3, :email])
    |> validate_change(:track_url_1, &validate_track_url/2)
    |> validate_change(:track_url_2, &validate_track_url/2)
    |> validate_change(:track_url_3, &validate_track_url/2)
    |> maybe_preserve_not_found_errors()
  end

  def validate_track_url(field, track_url) do
    if SSpotify.valid_track_url?(track_url) do
      []
    else
      Keyword.put([], field, "link is not recognised")
    end
  end

  defp resolve_tracks(changeset = %{valid?: true}) do
    track_urls = [
      fetch_change!(changeset, :track_url_1),
      fetch_change!(changeset, :track_url_2),
      fetch_change!(changeset, :track_url_3)
    ]

    SSpotify.tracks_from(track_urls)
  end

  defp resolve_tracks(changeset) do
    changeset
  end

  defp mark_field_as_missing(url, changeset) do
    error_text = "track is not found"

    field =
      changeset.data.__struct__.__schema__(:fields)
      |> Enum.find(fn field ->
        case fetch_change(changeset, field) do
          {:ok, ^url} ->
            field_errors = Keyword.get_values(changeset.errors, field)
            already_marked_as_not_found = Enum.find(field_errors, &(elem(&1, 0) == error_text))

            if already_marked_as_not_found do
              false
            else
              true
            end

          _ ->
            false
        end
      end)

    if field do
      not_found_field = String.to_existing_atom("#{field}_not_found")

      changeset
      |> put_change(not_found_field, true)
      |> add_error(field, error_text)
    else
      changeset
    end
  end

  defp find_track!(tracks, track_url) do
    track_id = SSpotify.extract_track_id!(track_url)
    track = Enum.find(tracks, &(&1.id == track_id))
    if track == nil, do: raise("can't find track #{track_id} in #{inspect(track)}")

    track
  end

  defp maybe_preserve_not_found_errors(changeset) do
    Enum.reduce([:track_url_1, :track_url_2, :track_url_3], changeset, fn field, acc ->
      not_found_field = String.to_existing_atom("#{field}_not_found")

      case {get_field(acc, not_found_field), fetch_change(acc, field)} |> dbg do
        {true, :error} ->
          # Field was marked as not found and hasn't changed
          add_error(acc, field, "track is not found")

        _ ->
          acc
      end
    end)
  end
end
