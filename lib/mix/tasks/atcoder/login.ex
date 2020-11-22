defmodule Mix.Tasks.Atcoder.Login do

  use Mix.Task

  alias ExAtcoder.HttpClient

  @base_url "https://atcoder.jp"

  def run([username, password]) do
    Application.ensure_all_started(:hackney)

    body = HttpClient.get(@base_url <> "/login")

    csrf_token =
      body
      |> Floki.parse_document!()
      |> Floki.attribute("input[name=csrf_token]", "value")
      |> List.first()

    params =
      [
        username: username,
        password: password,
        csrf_token: csrf_token
      ]

    HttpClient.post(@base_url <> "/login", params)
  end

end
