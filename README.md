# Cronfab

Hate reading and writing crontab? Turn your sad into fab with Cronfab!

## Examples
```elixir

iex> Cronfab.generate_crontab()
{:ok, "* * * * *"}

iex> Cronfab.generate_crontab(on: :weekends, at: "5:45pm", utc_offset: "-4")
{:ok, "45 21 * * 6,0"}

iex> Cronfab.generate_crontab(day: :every_day, at: :noon, utc_offset: "-5")
{:ok,  "0 17 * * *"}


iex> Cronfab.generate_crontab(on: :thursdays, at: "3:04pm")
{:ok, "4 15 * * 4"}
```

or

```elixir
iex> Cronfab.generate_crontab!()
"* * * * *"

iex> Cronfab.generate_crontab!(on: :weekends, at: "5:45pm", utc_offset: "-4")
"45 21 * * 6,0"

iex> Cronfab.generate_crontab!(day: :every_day, at: :noon, utc_offset: "-5")
"0 17 * * *"


iex> Cronfab.generate_crontab!(on: :thursdays, at: "3:04pm")
"4 15 * * 4"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cronfab` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cronfab, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/cronfab](https://hexdocs.pm/cronfab).

