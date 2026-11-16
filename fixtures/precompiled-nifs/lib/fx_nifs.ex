defmodule FxNifs do
  def check do
    {:ok, db} = Exqlite.Sqlite3.open(":memory:")
    {:ok, statement} = Exqlite.Sqlite3.prepare(db, "select 40 + 2")
    {:row, [sqlite]} = Exqlite.Sqlite3.step(db, statement)

    html = MDEx.to_html!("# hi")

    {:ok, image} = Vix.Vips.Operation.black(3, 2)

    actual = %{sqlite: sqlite, markdown: html, vips: {Vix.Vips.Image.width(image), Vix.Vips.Image.height(image)}}
    expected = %{sqlite: 42, markdown: "<h1>hi</h1>", vips: {3, 2}}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
