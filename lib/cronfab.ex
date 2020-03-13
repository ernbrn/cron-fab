defmodule Cronfab do
  @moduledoc """
  Hate reading and writing crontab? Turn your sad into fab with Cronfab!
  """

  @invalid_minute_error "Invalid minutes value given!"
  def invalid_minute_error, do: @invalid_minute_error

  @invalid_hour_error "Invalid hour value given!"
  def invalid_hour_error, do: @invalid_hour_error

  @invalid_am_pm_error "Invalid time given! Must include am or pm"
  def invalid_am_pm_error, do: @invalid_am_pm_error

  @invalid_offset_error "Invalid offset error! Must be in the form of '<operator><number>'"
  def invalid_offset_error, do: @invalid_offset_error

  defstruct minute: "*",
            hour: "*",
            day_of_month: "*",
            month: "*",
            day_of_week: "*",
            utc_offset: "0",
            utc_offset_operator: "+",
            error: nil

  @doc """
  Generates a crontab in UTC time. Any unspecified options will default to the every option (*).

  ## Examples
      iex> Cronfab.generate_crontab()
      {:ok, "* * * * *"}

      iex> Cronfab.generate_crontab(on: :weekends, at: "5:45pm", utc_offset: "-4")
      {:ok, "45 21 * * 6,0"}

      iex> Cronfab.generate_crontab(day: :every_day, at: :noon, utc_offset: "-5")
      {:ok,  "0 17 * * *"}


      iex> Cronfab.generate_crontab(on: :thursdays, at: "3:04pm")
      {:ok, "4 15 * * 4"}

  """
  def generate_crontab(args \\ []) do
    Enum.reduce(args, %Cronfab{}, fn arg, cron_map -> process_args(arg, cron_map) end)
    |> generate_cron
  end

  def generate_crontab!(args \\ []) do
    case generate_crontab(args) do
      {:ok, crontab} -> crontab
      {:error, error} -> raise ArgumentError, message: error
    end
  end

  ## private ##

  defp process_args({:day, :every_day}, map) do
    map
  end

  defp process_args({:day, :weekends}, map) do
    generate_on_weekends(map)
  end

  defp process_args({:on, :every_day}, map) do
    map
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
    case String.split(time, ":") do
      [hour, minute_am_pm] ->
        map
        |> process_time(hour, minute_am_pm)

      _ ->
        %{map | error: @invalid_minute_error}
    end
  end

  defp process_args({:utc_offset, offset}, map) do
    case String.split_at(offset, 1) do
      {_, ""} ->
        %{map | error: @invalid_offset_error}

      {utc_offset_operator, utc_offset} ->
        map
        |> process_offset(utc_offset_operator, utc_offset)
    end
  end

  defp process_args(invalid_option, map) do
    IO.warn("Warning: invalid option passed in, and will be ignored: #{inspect(invalid_option)}")
    map
  end

  defp process_offset(map, operator, offset) do
    case operator do
      value when value in ["+", "-"] ->
        %{map | utc_offset: offset, utc_offset_operator: operator}

      _ ->
        %{map | error: @invalid_offset_error}
    end
  end

  defp process_time(map, hour, minute_am_pm) do
    case String.split_at(minute_am_pm, 2) do
      {_, ""} ->
        %{map | error: @invalid_am_pm_error}

      {minute, time_of_day} ->
        process_minute_and_time_of_day(map, hour, minute, time_of_day)
    end
  end

  defp process_minute_and_time_of_day(map, hour, minute, time_of_day) do
    case time_of_day do
      value when value in ["am", "pm"] ->
        %{
          map
          | hour: military_hour(hour, time_of_day),
            minute: remove_extra_zero(minute)
        }

      _ ->
        %{map | error: @invalid_am_pm_error}
    end
  end

  defp military_hour("12", "am") do
    0
  end

  defp military_hour("12", "pm") do
    12
  end

  defp military_hour(hour, "am") do
    case String.to_integer(hour) > 12 do
      true -> :error
      false -> remove_extra_zero(hour)
    end
  end

  defp military_hour(hour, "pm") do
    String.to_integer(hour) + 12
  end

  defp military_hour(_, _) do
    :error
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
         utc_offset_operator: utc_offset_operator,
         error: error
       }) do
    with :ok <- surface_error(error),
         :ok <- validate_hour(hour),
         :ok <- validate_minute(minute) do
      hour_in_utc = calculate_utc_hour(hour, utc_offset, utc_offset_operator)
      {:ok, "#{minute} #{hour_in_utc} #{day_of_month} #{month} #{day_of_week}"}
    else
      error -> error
    end
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

  defp surface_error(nil) do
    :ok
  end

  defp surface_error(error) do
    {:error, error}
  end

  defp validate_minute("*") do
    :ok
  end

  defp validate_minute(:error) do
    {:error, @invalid_minute_error}
  end

  defp validate_minute(minute) do
    if minute < 60, do: :ok, else: {:error, @invalid_minute_error}
  end

  defp validate_hour("*") do
    :ok
  end

  defp validate_hour(:error) do
    {:error, @invalid_hour_error}
  end

  defp validate_hour(hour) do
    if hour <= 24, do: :ok, else: {:error, @invalid_hour_error}
  end
end
