defmodule Mix.Tasks.Atcoder.New do
  @shortdoc "指定されたコンテストの問題の雛形を作成します"

  use Mix.Task
  alias ExAtCoder.Repo

  def run([contest | _t]) do
    Application.ensure_all_started(:hackney)

    Repo.contest_tasks(contest)
    |> Enum.each(fn {p, [url]} -> make_code(contest, p, url) end)

    IO.puts("✨ Generate code for #{contest}")
    IO.puts("👍 Good Luck")
  end

  def make_code(contest, problem, url) do

    # ディレクトリ作成
    dir = "lib/#{contest}"
    unless File.exists?(dir) do
      Mix.Generator.create_directory(dir)
    end

    # 提出コード雛形作成
    file = dir <> "/#{Macro.underscore(problem)}.ex"
    unless File.exists?(file) do
      namespace = "#{Macro.camelize(contest)}.#{Macro.camelize(problem)}"
      genenrate_code(file, namespace)
    end

    # テストケース
    testcase_dir = dir <> "/test_case"
    unless File.exists?(testcase_dir) do
      Mix.Generator.create_directory(testcase_dir)
    end

    yaml = testcase_dir <> "/#{Macro.underscore(problem)}.yml"
    unless File.exists?(yaml) do
      cases =
        Repo.task_cases(url)
        |> Enum.map(fn {n, [input: input, output: output]} -> testcase_yaml(n, input, output) end)
        |> Enum.join("\n")

      Mix.Generator.create_file(yaml, cases)
    end

  end

  defp genenrate_code(file, namespace) do
    case Application.fetch_env(:ex_at_coder, :template_path) do
      :error ->
        code = default_template(namespace)
        Mix.Generator.create_file(file, code)

      {:ok, path} ->
        Mix.Generator.copy_template(path, file, [namespace: namespace])
    end

  end

  defp default_template(namespace) do
    """
    defmodule #{namespace}.Main do
      def main() do
      end
    end
    """
  end

  defp testcase_yaml(n, input, output) do
    """
    - name: sample#{n}
      in: |
        #{String.replace(input, "\r\n", "\n    ")}
      out: |
        #{String.replace(output, "\r\n", "\n    ")}
    """
  end

end
