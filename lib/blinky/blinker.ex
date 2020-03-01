defmodule Blinky.Blinker do
  @moduledoc """
  This module makes the leds blink
  """

  use GenServer

  require Logger

  alias Nerves.Leds

  @on_duration 100
  @off_duration 1000
  @time_between_blinks 100
  @poll_interval 1500

  def start_link(led_list) do
    GenServer.start_link(__MODULE__, led_list)
  end

  def init(led_list) do
    :timer.sleep(40000)
    spawn(fn -> poll(led_list) end)
    {:ok, self()}
  end

  defp poll(led_list) do
    :timer.sleep(@poll_interval)
    blinks_count = get_status()

    Enum.each(led_list, &blink(&1, blinks_count))

    poll(led_list)
  end

  defp get_status() do
    endpoint = Application.get_env(:blinky, :status_endpoint)

    HTTPoison.start
    response = HTTPoison.get!(
      endpoint,
      [],
      [ssl: [{:verify, :verify_none}]]
    )

    Logger.info("Response body: #{inspect(response.body)}")

    json_response = Jason.decode!(response.body)
    blinks = json_response["result"]["state"]

    blinks
  end

  defp blink(led_key, blinks_count) do
    Logger.info("blinking #{inspect blinks_count} times")

    if blinks_count != 0 do
      (1..blinks_count) |> Enum.each(fn _ ->
        Leds.set([{led_key, true}])
        :timer.sleep(@on_duration)
        Leds.set([{led_key, false}])
        :timer.sleep(@time_between_blinks)
      end)

      :timer.sleep(@off_duration)
    else
      Leds.set([{led_key, false}])
      :timer.sleep(@off_duration)
    end
  end
end
