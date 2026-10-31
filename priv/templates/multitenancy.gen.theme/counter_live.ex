defmodule <%= @module %>.CounterLive do
  @moduledoc "Sample LiveView of the <%= @name %> theme."

  use <%= @module %>, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_site={@current_site}>
      <p id="count">{@count}</p>
      <button id="increment" class="btn btn-primary" phx-click="increment">+1</button>
    </Layouts.app>
    """
  end
end
