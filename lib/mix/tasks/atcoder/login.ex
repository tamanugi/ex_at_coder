defmodule Mix.Tasks.Atcoder.Login do
  @shortdoc "AtCoderにログインします。"

  use Mix.Task

  alias ExAtCoder.Repo

  def run([username, password]) do
    Application.ensure_all_started(:hackney)
    case Repo.login(username, password) do
      :ok -> IO.puts("✨ login success.")
      :error -> IO.puts("👿 login failed. username and password is correct??")
    end
  end

end
