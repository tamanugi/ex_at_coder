defmodule ExAtCoder.Repo do
  alias ExAtcoder.HttpClient

  @base_url "https://atcoder.jp"
  @contest_url @base_url <> "/contests"

  def login(username, password) do

    csrf_token =
      HttpClient.get(@base_url <> "/login")
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

    login_user_name =
      HttpClient.get(@base_url)
      |> Floki.parse_document!()
      |> Floki.find("#navbar-collapse > ul.nav.navbar-nav.navbar-right > li:nth-child(2) > a")
      |> Floki.text()
      |> String.trim()

    case login_user_name do
      ^username -> :ok
      _ -> :error
    end
  end

  def absolute_url_for(path) do
    "#{@base_url}#{path}"
  end

  def contest_url_for(contest) do
    "#{@contest_url}/#{contest}"
  end

  def contest_tasks_url_for(contest) do
    "#{contest_url_for(contest)}/tasks"
  end

  def contest_tasks(contest) do
    body = HttpClient.get("#{@contest_url}/#{contest}/tasks")

    body
    |> Floki.parse_document!()
    |> Floki.find("table")
    |> Floki.find("tr > td:nth-child(1) > a")
    |> Enum.map(fn tag -> {Floki.text(tag), Floki.attribute(tag, "href")} end)
  end

  def task_cases(path) do
      body = HttpClient.get(@base_url <> path)
      Floki.parse_document!(body)
      |> Floki.find(".part > section")
      |> extract_sample()
  end

  defp extract_sample(_, acc \\ %{})
  defp extract_sample([{"section", _, [ {"h3", _, ["入力例 " <> n]}, {"pre", _, [input]} | _]} | t], acc) do
    extract_sample(t, update_sample_acc(acc, n, [input: input]))
  end
  defp extract_sample([{"section", _, [ {"h3", _, ["出力例 " <> n]}, {"pre", _, [input]} | _]} | t], acc) do
    extract_sample(t, update_sample_acc(acc, n, [output: input]))
  end
  defp extract_sample([], acc), do: acc |> Map.to_list()
  defp extract_sample([_ | t], acc), do: extract_sample(t, acc)

  defp update_sample_acc(map, key, value), do: Map.update(map, key, value, fn exists -> Keyword.merge(exists, value) end)

end
