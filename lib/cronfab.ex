defmodule Cronfab do
  @moduledoc """
  Hate reading and writing crontab? Turn your sad into fab with Cronfab!
  """

  defstruct minute: "*",
            hour: "*",
            day_of_month: "*",
            month: "*",
            day_of_week: "*",
            utc_offset: "0",
            utc_offset_operator: "+"

  @doc """
  Generates a crontab in UTC time. Any unspecified options will default to the every option (*).

  ## Examples

      iex> Cronfab.generate_crontab(on: :weekends, at: "5:45pm", utc_offset: "-4")
      "45 21 * * 6,0"

      iex> Cronfab.generate_crontab(day: :every_day, at: :noon, utc_offset: "-5")
      "0 17 * * *"

      iex> Cronfab.generate_crontab(on: :thursdays, at: "3:04pm")
      "4 15 * * 4"
  """
  def generate_crontab(args) do
    Enum.reduce(args, %Cronfab{}, fn arg, cron_map -> process_args(arg, cron_map) end)
    |> generate_cron
  end

  ## private ##

  defp process_args({:day, :every_day}, map) do
    map
  end

  defp process_args({:day, :weekends}, map) do
    generate_on_weekends(map)
  end

  defp process_args({:on, :weekends}, map) do
    generate_on_weekends(map)
  end

  defp process_args({:on, day_of_week}, map) do
    %{map | day_of_week: day_to_number(day_of_week)}
  end

  defp process_args({:at, :noon}, map) do
    %{map | hour: 12, minute: 0}
  end

  defp process_args({:at, time}, map) do
    [hour, minute_am_pm] = String.split(time, ":")
    {minute, time_of_day} = String.split_at(minute_am_pm, 2)

    %{map | hour: military_hour(hour, time_of_day), minute: remove_extra_zero(minute)}
  end

  defp process_args({:utc_offset, offset}, map) do
    {utc_offset_operator, utc_offset} = String.split_at(offset, 1)
    %{map | utc_offset: utc_offset, utc_offset_operator: utc_offset_operator}
  end

  defp process_args(invalid_option, map) do
    IO.warn("Warning: invalid option passed in, and will be ignored: #{inspect(invalid_option)}")
    map
  end

  defp military_hour("12", "am") do
    0
  end

  defp military_hour(hour, "am") do
    remove_extra_zero(hour)
  end

  defp military_hour(hour, "pm") do
    String.to_integer(hour) + 12
  end

  defp remove_extra_zero(string) do
    # remove an extra 0 if present
    string
    |> String.to_integer()
  end

  defp generate_cron(%Cronfab{
         day_of_month: day_of_month,
         day_of_week: day_of_week,
         hour: hour,
         minute: minute,
         month: month,
         utc_offset: utc_offset,
         utc_offset_operator: utc_offset_operator
       }) do
    hour_in_utc = calculate_utc_hour(hour, utc_offset, utc_offset_operator)

    "#{minute} #{hour_in_utc} #{day_of_month} #{month} #{day_of_week}"
  end

  defp calculate_utc_hour("*", _utc_offset, _utc_offest_operator) do
    "*"
  end

  defp calculate_utc_hour(hour, utc_offset, utc_offest_operator) do
    apply(:erlang, get_operator(utc_offest_operator), [
      hour,
      String.to_integer(utc_offset)
    ])
  end

  defp get_operator("+") do
    :-
  end

  defp get_operator("-") do
    :+
  end

  defp generate_on_weekends(map) do
    %{map | day_of_week: "#{day_to_number(:saturday)},#{day_to_number(:sunday)}"}
  end

  defp day_to_number(day) do
    %{
      sunday: 0,
      sundays: 0,
      monday: 1,
      mondays: 1,
      tuesday: 2,
      tuesdays: 2,
      wednesday: 3,
      wednesdays: 3,
      thursday: 4,
      thursdays: 4,
      friday: 5,
      fridays: 5,
      saturday: 6,
      saturdays: 6
    }[day]
  end
end
