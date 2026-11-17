defmodule FxNifs do
  def check do
    html = MDEx.to_html!("# hi")

    {:ok, image} = Vix.Vips.Operation.black(3, 2)

    actual = %{markdown: html, vips: {Vix.Vips.Image.width(image), Vix.Vips.Image.height(image)}}
    expected = %{markdown: "<h1>hi</h1>", vips: {3, 2}}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
