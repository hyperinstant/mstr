defmodule MstrWeb.ProfileTest do
  use ExUnit.Case, async: false
  alias MstrWeb.EnrollLive.Profile
  alias Mstr.DataCase

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

    test "returns {:error, changeset} even if only one track was not found" do
      track_id1 = "33qPnmgyN1aRVLQfbic2Sq"
      track_id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

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
                 "track_url_2" => "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=dae2b3b5e3134f40",
                 "track_url_3" => "https://open.spotify.com/track/#{track_id3}?si=8184109907ad4252"
               })

      assert DataCase.errors_on(changeset)[:track_url_1] == nil
      assert DataCase.errors_on(changeset)[:track_url_2] == ["track is not found"]
      assert DataCase.errors_on(changeset)[:track_url_3] == nil
    end

    test "populates fields for all missing tracks with the error" do
      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{
          "tracks" => [nil, nil, nil]
        })
      end)

      assert {:error, changeset} =
               Profile.resolve(%Profile{}, %{
                 "email" => "tes@example.com",
                 "nick" => "a nick",
                 "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb",
                 "track_url_2" => "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=dae2b3b5e3134f40",
                 "track_url_3" => "https://open.spotify.com/track/5y3mB1q4eauAdC0o9JgLGz?si=8184109907ad4252"
               })

      assert DataCase.errors_on(changeset)[:track_url_1] == ["track is not found"]
      assert DataCase.errors_on(changeset)[:track_url_2] == ["track is not found"]
      assert DataCase.errors_on(changeset)[:track_url_3] == ["track is not found"]
    end

    test "correctly populates fields for duplicated missing tracks" do
      track_id2 = "4xeOXTjSNsyF4djgo83SiR"
      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{
          "tracks" => [nil, SSpotify.Fixtures.track_json!(track_id2), nil]
        })
      end)

      assert {:error, changeset} =
               Profile.resolve(%Profile{}, %{
                 "email" => "tes@example.com",
                 "nick" => "a nick",
                 "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb",
                 "track_url_2" => "https://open.spotify.com/track/#{track_id2}",
                 "track_url_3" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb"
               })

      assert DataCase.errors_on(changeset)[:track_url_1] == ["track is not found"]
      assert DataCase.errors_on(changeset)[:track_url_2] == nil
      assert DataCase.errors_on(changeset)[:track_url_3] == ["track is not found"]
    end

    test "returns error even if only one track has malformed url" do
      assert {:error, changeset} =
               Profile.resolve(%Profile{}, %{
                 "email" => "tes@example.com",
                 "nick" => "a nick",
                 "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb",
                 "track_url_2" => "an invalid url",
                 "track_url_3" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb"
               })

      assert DataCase.errors_on(changeset)[:track_url_1] == nil
      assert DataCase.errors_on(changeset)[:track_url_2] == ["link is not recognised"]
      assert DataCase.errors_on(changeset)[:track_url_3] == nil
    end

    test "returns {:ok, profile} with tracks order exactly the were ordered in the form when all tracks were found" do
      email = "tes@example.com"
      nick = "a nick"
      track_id1 = "33qPnmgyN1aRVLQfbic2Sq"
      track_id2 = "4xeOXTjSNsyF4djgo83SiR"
      track_id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{
          "tracks" => Enum.map([track_id1, track_id2, track_id3], &SSpotify.Fixtures.track_json!/1)
        })
      end)

      assert {:ok,
              %{
                email: email,
                nick: nick,
                track_1: SSpotify.Fixtures.track!(track_id1),
                track_2: SSpotify.Fixtures.track!(track_id2),
                track_3: SSpotify.Fixtures.track!(track_id3)
              }} ==
               Profile.resolve(%Profile{}, %{
                 "email" => email,
                 "nick" => nick,
                 "track_url_1" => "https://open.spotify.com/track/#{track_id1}?si=cadde751415f4ebb",
                 "track_url_2" => "https://open.spotify.com/track/#{track_id2}?si=cadde751415f4ebb",
                 "track_url_3" => "https://open.spotify.com/track/#{track_id3}?si=cadde751415f4ebb"
               })
    end
  end

  test "preserves 'track not found' errors when fields are unchanged" do
    SSpotify.Fixtures.start_fake_token_manager()

    Req.Test.stub(SSpotify.ApiClient, fn conn ->
      Req.Test.json(conn, %{
        "tracks" => [nil, nil, nil]
      })
    end)

    # First, simulate a track not found error

    {:error, changeset} =
      Profile.resolve(%Profile{}, %{
        "email" => "tes@example.com",
        "nick" => "a nick",
        "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb",
        "track_url_2" => "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=dae2b3b5e3134f40",
        "track_url_3" => "https://open.spotify.com/track/5y3mB1q4eauAdC0o9JgLGz?si=8184109907ad4252"
      })

    # Then validate the same data again
    changeset =
      Profile.changeset(changeset.data, %{
        "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq"
      })

    assert DataCase.errors_on(changeset)[:track_url_1] == ["track is not found"]
  end

  test "clears 'track not found' error when field value changes" do
    SSpotify.Fixtures.start_fake_token_manager()

    Req.Test.stub(SSpotify.ApiClient, fn conn ->
      Req.Test.json(conn, %{
        "tracks" => [nil, nil, nil]
      })
    end)

    # First, simulate a track not found error
    {:error, changeset} =
      Profile.resolve(%Profile{}, %{
        "email" => "tes@example.com",
        "nick" => "a nick",
        "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=cadde751415f4ebb",
        "track_url_2" => "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=dae2b3b5e3134f40",
        "track_url_3" => "https://open.spotify.com/track/5y3mB1q4eauAdC0o9JgLGz?si=8184109907ad4252"
      })

    # Then validate with different URL
    changeset =
      Profile.changeset(changeset.data, %{
        "track_url_1" => "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR"
      })

    refute Keyword.has_key?(changeset.errors, :track_url_1)
    refute Ecto.Changeset.get_field(changeset, :track_url_1_not_found)
  end

  test "preserves 'track not found' errors for duplicate URLs independently" do
    # First, simulate track not found errors for duplicate URLs
    profile =
      %Profile{}
      |> Profile.change()
      |> Ecto.Changeset.put_change(:track_url_1_not_found, true)
      |> Ecto.Changeset.put_change(:track_url_3_not_found, true)
      |> Ecto.Changeset.put_change(:track_url_1, "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq")
      |> Ecto.Changeset.put_change(:track_url_3, "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq")
      |> Ecto.Changeset.add_error(:track_url_1, "track is not found")
      |> Ecto.Changeset.add_error(:track_url_3, "track is not found")

    # Validate the same data again
    changeset =
      Profile.changeset(profile.data, %{
        "track_url_1" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq",
        "track_url_3" => "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq"
      })

    assert DataCase.errors_on(changeset)[:track_url_1] == ["track is not found"]
    assert DataCase.errors_on(changeset)[:track_url_3] == ["track is not found"]
  end
end
