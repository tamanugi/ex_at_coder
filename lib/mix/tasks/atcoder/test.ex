defmodule Mix.Tasks.Atcoder.Test do
  @shortdoc "指定されたコンテスト,問題のテストケースを実行します。"

  use Mix.Task

  def run([contest, problem]) do
    Application.ensure_all_started(:ex_unit)

    file_path = file_path(contest, problem)
    mod = mod(contest, problem)

    # load testcase yaml
    path = Path.join(File.cwd!(), "lib/#{contest}/test_case/#{problem}.yml")
    {:ok, cases} = YamlElixir.read_from_file(path)

    test_case_number = length(cases)

    Mix.shell().info("#{contest} #{problem}")
    Mix.shell().info("running #{test_case_number} test...")

    cases
    |> Enum.each(fn c -> invoke(file_path, mod, c) end)
  end

  def run([contest, problem, input_file]) do
    Application.ensure_all_started(:ex_unit)

    file_path = file_path(contest, problem)
    mod = mod(contest, problem)
    test_in = Path.join(File.cwd!(), input_file) |> File.read!()

    invoke(file_path, mod, %{"name" => input_file, "in" => test_in, "out" => ""})
  end

  def run(_) do
    Mix.raise("usage mix atcoder.test [contest] [problem] [file path(option)]")
  end

  defp file_path(contest, problem), do: "lib/#{contest}/#{problem}.ex"
  defp mod(contest, problem) do
    [contest, problem, "Main"]
    |> Enum.map(fn s -> Macro.camelize(s) end)
    |> Module.concat()
  end

  defp invoke(file, mod, %{"in" => test_in, "out" => test_out, "name" => test_name}) do

    # In the context of a mix task, the "mod" is not loaded, so "require" is required
    Code.require_file(file)

    test_out = test_out |> String.trim()

    original_gl = Process.group_leader()
    {:ok, io} = StringIO.open(test_in, capture_prompt: false, encoding: :unicode)

    Process.group_leader(self(), io)

    {runtime, output} =
      try do
        {runtime, _} = :timer.tc(mod, :main, [])
        runtime
      catch
        _, _ ->
          {-1, :error}
      else
        runtime ->
          {:ok, {_input, output}} = StringIO.close(io)
          {runtime, output |> String.trim}
      after
        Process.group_leader(self(), original_gl)
      end

    status =
      case {runtime, output} do
        {_, :error} -> IO.ANSI.red_background <> IO.ANSI.white <> " RE " <> IO.ANSI.reset()
        {_, o} when o != test_out -> IO.ANSI.yellow_background <> IO.ANSI.black <> " WA " <> IO.ANSI.reset()
        {r, _} when r > 2000_000 -> IO.ANSI.yellow_background <> IO.ANSI.black <> " TLE " <> IO.ANSI.reset()
        _ -> IO.ANSI.green_background <> IO.ANSI.black <> " AC " <> IO.ANSI.reset()
      end

    Mix.shell().info("-------------------------------------")
    Mix.shell().info("" <> test_name <> " " <> status <> " #{div(runtime, 1000)}" <> "ms")
    Mix.shell().info("actual:\n#{output}")
    Mix.shell().info("expected:\n#{test_out}")
  end
end
