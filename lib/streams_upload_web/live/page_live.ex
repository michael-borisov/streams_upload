defmodule StreamsUploadWeb.PageLive do
  use StreamsUploadWeb, :live_view
  alias StreamsUpload.Block

  require Logger

  def render(assigns) do
    ~H"""
    <div class="rounded border p-6 mt-3">
      <.header class="text-center">
        Page
      </.header>

      <div class="bg-gray-100 py-4 rounded-lg">
        <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
          <div>
            <div
              id="timeline-items"
              phx-update="stream"
              class="grid grid-cols-1 gap-2"
              phx-hook="Sortable"
            >
              <div
                :for={{id, block_form} <- @streams.blocks}
                id={id}
                data-id={block_form.data.block_id}
                data-group="blocks"
                class="
          relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-2 shadow-sm
          focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400
          drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0
          "
              >
                <div class="flex">
                  <%= if block_form.data.type == "text" do %>
                    <.simple_form
                      for={block_form}
                      phx-change="block_validate"
                      phx-submit="save"
                      phx-value-id={block_form.data.id}
                      phx-value-block_id={block_form.data.block_id}
                      class="min-w-0 flex-1 drag-ghost:opacity-0"
                    >
                      <div class="flex drag-ghost:opacity-0">
                        <div class="flex-auto block text-sm leading-6 text-zinc-900">
                          <.input type="hidden" name="block_type" value="text" />
                          <.input
                            field={block_form[:text]}
                            type="text"
                            label="text"
                            phx-value-block_id={block_form.data.block_id}
                          />
                        </div>
                      </div>
                    </.simple_form>
                  <% end %>

                  <%= if block_form.data.type == "photo" do %>
                    <section phx-drop-target={@uploads["photo-#{block_form.data.block_id}"].ref}>
                      <%!-- render each photo entry --%>
                      <%= for entry <- @uploads["photo-#{block_form.data.block_id}"].entries do %>
                        <article class="upload-entry">
                          <div class="flex flex-wrap justify-center">
                            <div>
                              <figure>
                                <.live_img_preview entry={entry} class="rounded" />
                              </figure>
                              <figcaption><%= entry.client_name %></figcaption>
                            </div>
                          </div>
                          <%!-- entry.progress will update automatically for in-flight entries --%>
                          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                          <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
                          <button
                            type="button"
                            phx-click="cancel-upload"
                            phx-value-ref={entry.ref}
                            aria-label="cancel"
                          >
                            &times;
                          </button>

                          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
                          <%= for err <- upload_errors(@uploads["photo-#{block_form.data.block_id}"], entry) do %>
                            <p class="alert alert-danger"><%= error_to_string(err) %></p>
                          <% end %>
                        </article>
                      <% end %>

                      <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
                      <%= for err <- upload_errors(@uploads["photo-#{block_form.data.block_id}"]) do %>
                        <p class="alert alert-danger"><%= error_to_string(err) %></p>
                      <% end %>
                    </section>

                    <form phx-submit="save" phx-change="validate_photo">
                      <.live_file_input upload={@uploads["photo-#{block_form.data.block_id}"]} />
                    </form>
                  <% end %>

                  <button
                    type="button"
                    class="w-10 -mt-1 flex-none"
                    phx-click="delete_block"
                    phx-value-block_id={block_form.data.block_id}
                  >
                    <.icon name="hero-x-mark" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <.button
            type="button"
            class="align-middle ml-2"
            phx-click="add_text_block"
            disabled={
              Enum.count(@blocks) > 0 and
                Enum.any?(@blocks, fn i -> i.type === "text" and is_nil(i.data) end)
            }
          >
            add text
          </.button>
          <.button
            type="button"
            class="align-middle ml-2"
            phx-click="add_photo_block"
            disabled={
              Enum.count(@blocks) > 0 and
                Enum.any?(@blocks, fn i -> i.type === "photo" and is_nil(i.data) end)
            }
          >
            add photo
          </.button>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    post = %{blocks: []}

    {:ok,
     assign(socket, is_loading: false, page_title: "Page", post: post)
     |> assign(:blocks, [])
     |> assign(:uploaded_files, [])
     |> stream(:blocks, post.blocks)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "reposition",
        %{"id" => block_id, "new" => new_idx, "old" => _} = _params,
        socket
      ) do
    Logger.debug("reposition #{block_id}, new #{new_idx}")

    %{blocks: blocks} = socket.assigns

    {:noreply, socket |> assign(:blocks, blocks)}
  end

  def handle_event("new", %{"at" => at}, socket) do
    Logger.debug("new at #{at}")
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    Logger.debug("Save post")
    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "validate")
    {:noreply, socket}
  end

  def handle_event("validate_photo", params, socket) do
    IO.inspect(params, label: "validate photo")
    {:noreply, socket}
  end

  def handle_event(
        "block_validate",
        %{"block_id" => block_id, "block" => block_data, "block_type" => block_type},
        socket
      ) do
    %{blocks: blocks} = socket.assigns

    blocks =
      Enum.map(
        blocks,
        fn i ->
          if i.block_id == String.to_integer(block_id) do
            Map.put(i, :data, block_data) |> Map.put(:type, block_type)
          else
            i
          end
        end
      )

    {
      :noreply,
      socket
      |> assign(:blocks, blocks)
    }
  end

  def handle_event("format", %{"format" => format}, socket) do
    {:noreply, assign(socket, :format, format)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("add_text_block", _unsigned_params, socket) do
    %{blocks: blocks} = socket.assigns

    block_id = Enum.count(blocks) + 1
    block = build_block(block_id, "text")

    {:noreply,
     socket
     |> assign(blocks: blocks ++ [block])
     |> stream_insert(
       :blocks,
       to_change_form(block, %{text: ""}, block_id),
       at: -1
     )}
  end

  def handle_event("add_photo_block", _unsigned_params, socket) do
    %{blocks: blocks} = socket.assigns

    block_id = Enum.count(blocks) + 1
    block = build_block(block_id, "photo")

    {:noreply,
     socket
     |> allow_upload(
       "photo-#{block_id}",
       accept: ~w(image/*),
       max_entries: 1,
       auto_upload: true
     )
     |> assign(blocks: blocks ++ [block])
     |> stream_insert(
       :blocks,
       to_change_form(block, %{photo: ""}, block_id),
       at: -1
     )}
  end

  def handle_event("delete_block", %{"block_id" => block_id} = _unsigned_params, socket) do
    block = build_block(block_id)
    %{blocks: blocks} = socket.assigns

    blocks =
      Enum.filter(blocks, fn i ->
        i.block_id != String.to_integer(block_id)
      end)

    {:noreply,
     socket
     |> assign(:blocks, blocks)
     |> stream_delete(:blocks, to_change_form(block, %{text: ""}, block_id))}
  end

  defp to_change_form(block_or_changeset, params, block_id) do
    changeset =
      block_or_changeset
      |> Block.block_changeset(params)

    to_form(changeset, as: "block", id: "form-block-#{block_id}")
  end

  defp build_block(block_id) when is_integer(block_id),
    do: %Block{block_id: block_id, position: block_id - 1}

  defp build_block(block_id) when is_binary(block_id) do
    String.to_integer(block_id) |> build_block()
  end

  defp build_block(block_id, type) when is_integer(block_id),
    do: %Block{block_id: block_id, position: block_id - 1, type: type}

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
