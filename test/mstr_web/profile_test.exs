defmodule MstrWeb.ProfileTest do
  use ExUnit.Case, async: true
  alias MstrWeb.EnrollLive.Profile
  alias Mstr.DataCase
  alias SSpotify.Fixtures, as: SSpotifyFixtures

  describe "resolve" do
    test "returns {:error, changeset} if there are validation errors" do
      assert {:error, changeset} =
               Profile.resolve(%Profile{}, %{
                 "email" => "tes@example.com",
                 "nick" => "a nick",
                 "track_url_1" => "an invalid url",
                 "track_url_2" => "",
                 "track_url_3" => "https://open.spotify.com/track/00IYyMln3hUcleQgQLeSOIXXX?si=8184109907ad4252"
               })

      assert changeset.valid? == false
      assert DataCase.errors_on(changeset)[:track_url_1] == ["link is not recognised"]
      assert DataCase.errors_on(changeset)[:track_url_2] == ["can't be blank"]
      assert DataCase.errors_on(changeset)[:track_url_3] == ["link is not recognised"]
    end

    test "populates faulty track url field with the error" do
      track_id1 = "33qPnmgyN1aRVLQfbic2Sq"
      track_id2 = "4xeOXTjSNsyF4djgo83SiR"
      track_id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotifyFixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{
          "tracks" => [SSpotify.Fixtures.track_json!(track_id1), nil, SSpotify.Fixtures.track_json!(track_id3)]
        })
      end)

      assert {:error, changeset} =
               Profile.resolve(%Profile{}, %{
                 "email" => "tes@example.com",
                 "nick" => "a nick",
                 "track_url_1" => "https://open.spotify.com/track/#{track_id1}?si=cadde751415f4ebb",
                 "track_url_2" => "https://open.spotify.com/track/#{track_id2}?si=dae2b3b5e3134f40",
                 "track_url_3" => "https://open.spotify.com/track/#{track_id3}?si=8184109907ad4252"
               })

      assert DataCase.errors_on(changeset)[:track_url_1] == nil
      assert DataCase.errors_on(changeset)[:track_url_2] == ["track is not found"]
      assert DataCase.errors_on(changeset)[:track_url_3] == nil
    end

    test "populates faulty track url fields with the error"
    test "returns {:ok, profile} with tracks order exactly the were ordered in the form"
  end
end
