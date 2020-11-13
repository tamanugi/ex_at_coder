defmodule Mix.Tasks.Atcoder.Test do
  use Mix.Task

  def run([contest, problem]) do
    Application.ensure_all_started(:ex_unit)

    mod =
      [contest, problem, "Main"]
      |> Enum.map(fn s -> Macro.camelize(s) end)
      |> Module.concat()

    # load testcase yaml
    path = Path.join(File.cwd!(), "lib/#{contest}/test_case/#{problem}.yml")
    {:ok, cases} = YamlElixir.read_from_file(path)

    test_case_number = length(cases)

    IO.puts("#{contest} #{problem}")
    IO.puts("running #{test_case_number} test...")

    cases
    |> Enum.each(fn c -> invoke(mod, c) end)
  end

  defp invoke(mod, %{"in" => test_in, "out" => test_out, "name" => test_name}) do

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

    IO.puts("-------------------------------------")
    IO.puts("" <> test_name <> " " <> status <> " #{div(runtime, 1000)}" <> "ms")
    IO.puts("actual:\n#{output}")
    IO.puts("expected:\n#{test_out}")
  end
end