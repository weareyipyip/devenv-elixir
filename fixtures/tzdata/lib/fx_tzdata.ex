defmodule FxTzdata do
  def check do
    {:ok, _} = Application.ensure_all_started(:tzdata)
    {:ok, datetime} = DateTime.shift_zone(~U[2026-07-01 12:00:00Z], "Europe/Amsterdam", Tzdata.TimeZoneDatabase)

    actual = %{autoupdate: Application.get_env(:tzdata, :autoupdate), hour: datetime.hour}
    if actual == %{autoupdate: :disabled, hour: 14}, do: "ok", else: inspect(actual)
  end
end
