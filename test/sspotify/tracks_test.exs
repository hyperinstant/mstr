defmodule SSpotify.TracksTest do
  use ExUnit.Case, async: true
  alias SSpotify
  alias SSpotify.Errors.InvalidTrackURLs

  describe "SSpotify.tracks/1" do
    test "returns Error.InvalidTracks when url does not start with https://open.spotify.com/track/" do
      urls = ["an invalid url"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks when url does not have a valid track id" do
      urls = ["https://open.spotify.com/track/an-invalid-id"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks with all track when all tracks are invalid (wrong url)" do
      urls = ["an invalid url 1", "an invalid url 2", "an invalid url 3"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks with multiple invalid track when some of them are invalid (wrong url)" do
      invalid_url_1 = "an invalid url 1"
      invalid_url_2 = "an invalid url 2"

      urls = [
        invalid_url_1,
        "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=0dd7da796ab14cd2",
        invalid_url_2
      ]

      assert {:error, %InvalidTrackURLs{urls: [invalid_url_1, invalid_url_2]}} == SSpotify.tracks_from(urls)
    end

    test "returns found tracks in the same order" do
      id1 = "33qPnmgyN1aRVLQfbic2Sq"
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => Enum.map([id1, id2, id3], &SSpotify.Fixtures.track_json!/1)})
      end)

      assert {:ok, %{found: found_tracks}} =
               SSpotify.tracks_from([
                 "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
               ])

      assert found_tracks == Enum.map([id1, id2, id3], &SSpotify.Fixtures.track!/1)
    end

    test "returns missing urls in {:ok, %{missing: [...]}" do
      id1 = "33qPnmgyN1aRVLQfbic2Sq"
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [SSpotify.Fixtures.track_json!(id2)]})
      end)

      assert {:ok, %{missing: missing_tracks}} =
               SSpotify.tracks_from([
                 "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
               ])

      assert missing_tracks == [
               "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
               "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
             ]
    end

    test "returns result map with empty `missing` field when all tracks are found" do
      id1 = "33qPnmgyN1aRVLQfbic2Sq"
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => Enum.map([id1, id2, id3], &SSpotify.Fixtures.track_json!/1)})
      end)

      assert {:ok, %{missing: []}} =
               SSpotify.tracks_from([
                 "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
               ])
    end

    test "returns result map with empty `found` field when all tracks are missing" do
      id1 = "33qPnmgyN1aRVLQfbic2Sq"
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      id3 = "5y3mB1q4eauAdC0o9JgLGz"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [nil, nil, nil]})
      end)

      assert {:ok, %{found: []}} =
               SSpotify.tracks_from([
                 "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
               ])
    end

    test "puts all urls for missing track in the `missing` field when all tracks are missing" do
      urls = [
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39",
        "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=0dd7da796ab14cd2",
        "https://open.spotify.com/track/5y3mB1q4eauAdC0o9JgLGz?si=16f565fbc24249f7"
      ]

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [nil, nil, nil]})
      end)

      assert {:ok, %{missing: ^urls}} = SSpotify.tracks_from(urls)
    end

    test "correctly detects missing urls even if they're duplicated (all urls duplicated)" do
      urls = [
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39",
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39",
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39"
      ]

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [nil, nil, nil]})
      end)

      assert {:ok, %{missing: ^urls}} = SSpotify.tracks_from(urls)
    end

    test "correctly detects missing urls even if they're duplicated (2/3 urls are duplicated)" do
      urls = [
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39",
        "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=0dd7da796ab14cd2",
        "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39"
      ]

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [nil, nil, nil]})
      end)

      assert {:ok, %{missing: ^urls}} = SSpotify.tracks_from(urls)
    end

    test "correctly detects duplicated missing urls when one track is found" do
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      missing_url = "https://open.spotify.com/track/33qPnmgyN1aRVLQfbic2Sq?si=462304c8a05c4d39"

      SSpotify.Fixtures.start_fake_token_manager()

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => [nil, SSpotify.Fixtures.track_json!(id2), nil]})
      end)

      assert {:ok, %{missing: [missing_url, missing_url], found: [SSpotify.Fixtures.track!(id2)]}} ==
               SSpotify.tracks_from([
                 missing_url,
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 missing_url
               ])
    end
  end
end
