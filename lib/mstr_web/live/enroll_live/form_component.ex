defmodule MstrWeb.PersonLive.FormComponent do
  use MstrWeb, :live_component

  alias MstrWeb.EnrollLive.Profile

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} id="profile-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:nick]} type="text" label="Nick" required={true} phx-debounce="blur" />
        <.input field={@form[:track_url_1]} type="text" label="Song  #1 (Spotify link)" required={true} phx-debounce="blur" />
        <.input field={@form[:track_url_2]} type="text" label="Song  #2 (Spotify link)" required={true} phx-debounce="blur" />
        <.input field={@form[:track_url_3]} type="text" label="Song  #2 (Spotify link)" required={true} phx-debounce="blur" />
        <.input field={@form[:email]} type="text" label="Email" required={true} phx-debounce="blur" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Person</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{profile: profile} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Profile.change(profile))
     end)}
  end

  @impl true
  def handle_event("validate", %{"profile" => profile_params}, socket) do
    changeset = Profile.change(socket.assigns.profile, profile_params)

    {:noreply,
     socket
     |> assign(:profile, changeset.data)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    case Profile.resolve(socket.assigns.profile, profile_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}

      {:ok, profile} ->
        notify_parent({:saved, profile})

        {:noreply,
         socket
         |> put_flash(:info, "Person saved successfully")
         |> push_patch(to: ~p"/")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
