defmodule Mix.Tasks.Atcoder.New do
  @shortdoc "指定されたコンテストの問題の雛形を作成します"

  use Mix.Task
  alias ExAtCoder.Repo

  def run([contest | _t]) do
    Application.ensure_all_started(:hackney)

    Repo.contest_tasks(contest)
    |> Enum.each(fn {p, [url]} -> make_code(contest, p, url) end)
  end

  def make_code(contest, problem, url) do
    namespace = "#{Macro.camelize(contest)}.#{Macro.camelize(problem)}"

    code = CodeTemplate.make(namespace)

    # ディレクトリ作成
    dir = "lib/#{contest}"
    File.mkdir(dir)

    # 提出コード雛形作成
    file = dir <> "/#{Macro.underscore(problem)}.ex"
    unless File.exists?(file) do
      File.write(file, code)
      IO.puts("#{file} create ✨")
    end

    # テストケース
    testcase_dir = dir <> "/test_case"
    File.mkdir(testcase_dir)

    yaml = testcase_dir <> "/#{Macro.underscore(problem)}.yml"
    unless File.exists?(yaml) do
      cases =
        Repo.task_cases(url)
        |> Enum.map(fn {n, [input: input, output: output]} -> testcase_yaml(n, input, output) end)
        |> Enum.join("\n")

      File.write!(yaml, cases)

      IO.puts("#{yaml} create ✨")
    end

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

defmodule CodeTemplate do
  require EEx
  EEx.function_from_file(:def, :make, "lib/template.eex", [:namespace])
end
