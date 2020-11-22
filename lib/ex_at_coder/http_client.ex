defmodule ExAtcoder.HttpClient do
  alias ExAtcoder.CookieStore

  def request(method, url, params) do
    payload = URI.encode_query(params)
    cookies = CookieStore.get() || []
    try do
      response = case method do
        method when method in [:get, :delete] ->
          real_url = url <> "?" <> payload
          apply(HTTPoison, :"#{method}!", [
            real_url,
            %{},
            [hackney: [cookie: cookies]]])
        _ ->
          apply(HTTPoison, :"#{method}!", [
            url,
            payload,
            %{"Content-Type" => "application/x-www-form-urlencoded; charset=utf-8"},
            [hackney: [cookie: cookies]]])
      end

      case response.status_code do
        code when code >= 200 and code < 400 ->
          CookieStore.update(cookies(response))
          response.body
        code -> raise """
          Oops! #{code}
            URL: #{url}
            Method: #{method}
            Params: #{inspect params}
            Cookies: #{inspect cookies}
        """
      end
    rescue
      e in HTTPoison.Error ->
        raise """
          Oops! #{e.reason}!
            URL: #{url}
            Method: #{method}
            Params: #{inspect params}
            Cookies: #{inspect cookies}
        """
    end
  end

  for method <- [:get, :post, :patch, :put, :delete] do
    def unquote(method)(url, params \\ %{}) do
      request(unquote(method), url, params)
    end
  end

  defp cookies(%HTTPoison.Response{} = resp) do
    resp.headers
    |> Enum.filter(fn
      {"Set-Cookie", _} -> true
      _ -> false
    end)
    |> Enum.map(fn{_, cookie} -> cookie end)
  end
end
