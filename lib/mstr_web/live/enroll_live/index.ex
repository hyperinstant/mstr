defmodule MstrWeb.EnrollLive.Index do
  use MstrWeb, :live_view
  alias MstrWeb.EnrollLive.Profile

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Taadaa!")
      |> assign(:profile, %Profile{})

    {:ok, socket}
  end

  @impl true
  def handle_info({MstrWeb.PersonLive.FormComponent, {:saved, person}}, socket) do
    {:noreply, stream_insert(socket, :personalities, person)}
  end
end
