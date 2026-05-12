defmodule DisclosureAutomation.MarketCalendar do
  @moduledoc """
  Market-day helpers used by the delivery planner.

  The reference runtime keeps holidays caller-supplied to avoid baking in a
  third-party calendar dependency. Weekends are always treated as closed days.
  """

  def market_open_day?(%Date{} = date, holidays \\ []) do
    Date.day_of_week(date) not in [6, 7] and date not in holidays
  end

  def previous_open_day(%Date{} = date, holidays \\ []) do
    Stream.iterate(Date.add(date, -1), &Date.add(&1, -1))
    |> Enum.find(&market_open_day?(&1, holidays))
  end

  def next_open_day(%Date{} = date, holidays \\ []) do
    Stream.iterate(Date.add(date, 1), &Date.add(&1, 1))
    |> Enum.find(&market_open_day?(&1, holidays))
  end

  def market_day(%Date{} = date, holidays \\ []) do
    if market_open_day?(date, holidays), do: date, else: previous_open_day(date, holidays)
  end
end
