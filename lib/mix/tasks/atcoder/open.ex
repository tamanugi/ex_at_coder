defmodule Mix.Tasks.Atcoder.Open do
  @shortdoc "指定されたコンテストのWebページをブラウザで開きます"

  use Mix.Task
  alias ExAtCoder.Repo

  def run([contest]) do
    contest
    |> Repo.contest_url_for()
    |> BrowserLauncher.open()

    Mix.shell().info("✨ Open URL for #{contest}")
  end

  def run([contest, task]) do
    Application.ensure_all_started(:hackney)

    url =
      Repo.contest_tasks(contest)
      |> Enum.find(fn {p, [_]} ->
        String.downcase(p) == String.downcase(task)
      end)

    case url do
      {_, [url]} ->
        url
        |> Repo.absolute_url_for()
        |> BrowserLauncher.open()

        Mix.shell().info("✨ Open URL for #{contest} #{task}")

      nil ->
        Mix.shell().info("👿 No such URL found")
    end
  end
end
