defmodule ExAtcoder.CookieStore do

  @cookie_store_file "cookie.txt"

  def get() do
    case File.read(@cookie_store_file) do
      {:ok, cookies} -> cookies
      {:error, _} -> nil
    end
  end

  def update(cookies) when is_list(cookies) do
    File.write!(@cookie_store_file, cookies |> Enum.join(";"))
  end

end
