defmodule CronfabTest do
  use ExUnit.Case
  doctest Cronfab

  describe "generate_crontab" do
    test "with no options given, it will generate a crontab for every minute of every day" do
      assert Cronfab.generate_crontab() == {:ok, "* * * * *"}
    end

    test "the :day option" do
      assert Cronfab.generate_crontab(day: :every_day) == {:ok, "* * * * *"}
      assert Cronfab.generate_crontab(day: :weekends) == {:ok, "* * * * 6,0"}
    end

    test "the :on option" do
      days_of_the_week = [
        "sunday",
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday"
      ]

      assert Cronfab.generate_crontab(on: :every_day) == {:ok, "* * * * *"}
      assert Cronfab.generate_crontab(on: :weekends) == {:ok, "* * * * 6,0"}

      days_of_the_week
      |> Enum.with_index()
      |> Enum.each(fn {day, index} ->
        assert Cronfab.generate_crontab(on: String.to_atom(day)) == {:ok, "* * * * #{index}"}

        assert Cronfab.generate_crontab(on: String.to_atom(day <> "s")) ==
                 {:ok, "* * * * #{index}"}
      end)
    end

    test "valid :at options" do
      assert Cronfab.generate_crontab(at: :noon) == {:ok, "0 12 * * *"}
      assert Cronfab.generate_crontab(at: "12:00pm") == {:ok, "0 12 * * *"}
      assert Cronfab.generate_crontab(at: "12:00am") == {:ok, "0 0 * * *"}
      assert Cronfab.generate_crontab(at: "1:00pm") == {:ok, "0 13 * * *"}
      assert Cronfab.generate_crontab(at: "8:00am") == {:ok, "0 8 * * *"}
      assert Cronfab.generate_crontab(at: "2:22pm") == {:ok, "22 14 * * *"}
      assert Cronfab.generate_crontab(at: "9:59pm") == {:ok, "59 21 * * *"}
    end

    test "invalid :at options" do
      assert Cronfab.generate_crontab(at: "4:65am") == {:error, Cronfab.invalid_minute_error()}
      assert Cronfab.generate_crontab(at: "12am") == {:error, Cronfab.invalid_minute_error()}
      assert Cronfab.generate_crontab(at: "5") == {:error, Cronfab.invalid_minute_error()}
      assert Cronfab.generate_crontab(at: "") == {:error, Cronfab.invalid_minute_error()}

      assert Cronfab.generate_crontab(at: "13:00am") == {:error, Cronfab.invalid_hour_error()}
      assert Cronfab.generate_crontab(at: "44:00am") == {:error, Cronfab.invalid_hour_error()}

      assert Cronfab.generate_crontab(at: "5:00") == {:error, Cronfab.invalid_am_pm_error()}
      assert Cronfab.generate_crontab(at: "5:00") == {:error, Cronfab.invalid_am_pm_error()}
      assert Cronfab.generate_crontab(at: "3:00fm") == {:error, Cronfab.invalid_am_pm_error()}
    end

    test "valid :utc_offset" do
      assert Cronfab.generate_crontab(utc_offset: "-4") == {:ok, "* * * * *"}
      assert Cronfab.generate_crontab(at: "3:00am", utc_offset: "-4") == {:ok, "0 7 * * *"}
      assert Cronfab.generate_crontab(at: "3:33pm", utc_offset: "-4") == {:ok, "33 19 * * *"}
      assert Cronfab.generate_crontab(at: :noon, utc_offset: "-8") == {:ok, "0 20 * * *"}
    end

    test "invalid :utc_offset" do
      assert Cronfab.generate_crontab(utc_offset: "4") == {:error, Cronfab.invalid_offset_error()}
      assert Cronfab.generate_crontab(utc_offset: "") == {:error, Cronfab.invalid_offset_error()}

      assert Cronfab.generate_crontab(utc_offset: "3+") ==
               {:error, Cronfab.invalid_offset_error()}

      assert Cronfab.generate_crontab(utc_offset: "~6") ==
               {:error, Cronfab.invalid_offset_error()}
    end
  end

  # TODO: find a way to make this less repetitive
  describe "generate_crontab!" do
    test "with no options given, it will generate a crontab for every minute of every day" do
      assert Cronfab.generate_crontab!() == "* * * * *"
    end

    test "the :day option" do
      assert Cronfab.generate_crontab!(day: :every_day) == "* * * * *"
      assert Cronfab.generate_crontab!(day: :weekends) == "* * * * 6,0"
    end

    test "the :on option" do
      days_of_the_week = [
        "sunday",
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday"
      ]

      assert Cronfab.generate_crontab!(on: :every_day) == "* * * * *"
      assert Cronfab.generate_crontab!(on: :weekends) == "* * * * 6,0"

      days_of_the_week
      |> Enum.with_index()
      |> Enum.each(fn {day, index} ->
        assert Cronfab.generate_crontab!(on: String.to_atom(day)) == "* * * * #{index}"

        assert Cronfab.generate_crontab!(on: String.to_atom(day <> "s")) ==
                 "* * * * #{index}"
      end)
    end

    test "valid :at options" do
      assert Cronfab.generate_crontab!(at: :noon) == "0 12 * * *"
      assert Cronfab.generate_crontab!(at: "12:00pm") == "0 12 * * *"
      assert Cronfab.generate_crontab!(at: "12:00am") == "0 0 * * *"
      assert Cronfab.generate_crontab!(at: "1:00pm") == "0 13 * * *"
      assert Cronfab.generate_crontab!(at: "8:00am") == "0 8 * * *"
      assert Cronfab.generate_crontab!(at: "2:22pm") == "22 14 * * *"
      assert Cronfab.generate_crontab!(at: "9:59pm") == "59 21 * * *"
    end

    test "invalid :at options" do
      assert_raise ArgumentError,
                   Cronfab.invalid_minute_error(),
                   fn -> Cronfab.generate_crontab!(at: "4:65am") end

      assert_raise ArgumentError,
                   Cronfab.invalid_minute_error(),
                   fn -> Cronfab.generate_crontab!(at: "12am") end

      assert_raise ArgumentError,
                   Cronfab.invalid_minute_error(),
                   fn -> Cronfab.generate_crontab!(at: "5") end

      assert_raise ArgumentError,
                   Cronfab.invalid_minute_error(),
                   fn -> Cronfab.generate_crontab!(at: "") end

      assert_raise ArgumentError,
                   Cronfab.invalid_hour_error(),
                   fn -> Cronfab.generate_crontab!(at: "13:00am") end

      assert_raise ArgumentError,
                   Cronfab.invalid_hour_error(),
                   fn -> Cronfab.generate_crontab!(at: "44:00am") end

      assert_raise ArgumentError,
                   Cronfab.invalid_am_pm_error(),
                   fn -> Cronfab.generate_crontab!(at: "5:00") end

      assert_raise ArgumentError,
                   Cronfab.invalid_am_pm_error(),
                   fn -> Cronfab.generate_crontab!(at: "5:00") end

      assert_raise ArgumentError,
                   Cronfab.invalid_am_pm_error(),
                   fn -> Cronfab.generate_crontab!(at: "3:00fm") end
    end

    test "valid :utc_offset" do
      assert Cronfab.generate_crontab!(utc_offset: "-4") == "* * * * *"
      assert Cronfab.generate_crontab!(at: "3:00am", utc_offset: "-4") == "0 7 * * *"
      assert Cronfab.generate_crontab!(at: "3:33pm", utc_offset: "-4") == "33 19 * * *"
      assert Cronfab.generate_crontab!(at: :noon, utc_offset: "-8") == "0 20 * * *"
    end

    test "invalid :utc_offset" do
      assert_raise ArgumentError,
                   Cronfab.invalid_offset_error(),
                   fn -> Cronfab.generate_crontab!(utc_offset: "4") end

      assert_raise ArgumentError,
                   Cronfab.invalid_offset_error(),
                   fn -> Cronfab.generate_crontab!(utc_offset: "") end

      assert_raise ArgumentError,
                   Cronfab.invalid_offset_error(),
                   fn -> Cronfab.generate_crontab!(utc_offset: "3+") end

      assert_raise ArgumentError,
                   Cronfab.invalid_offset_error(),
                   fn -> Cronfab.generate_crontab!(utc_offset: "~6") end
    end
  end
end
