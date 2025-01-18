defmodule SSpotify.Fixtures do
  alias SSpotify.Track

  def track!(id) do
    id
    |> track_json!()
    |> Track.from_json()
  end

  def track_json!(id) do
    "test/support/fixtures/tracks_json/#{id}.json"
    |> File.read!()
    |> JSON.decode!()
  end

  def start_fake_token_manager() do
    defmodule FakeAPIClient do
      def request_token!("a client id", "a client secret") do
        %{"access_token" => "a token", "expires_in" => 3600}
      end
    end

    ExUnit.Callbacks.start_supervised!(
      {SSpotify.TokenManager, %{client_id: "a client id", client_secret: "a client secret", api_client: FakeAPIClient}}
    )
  end
end
