defmodule Mix.Tasks.Atcoder.New do
  @shortdoc "指定されたコンテストの問題の雛形を作成します"

  use Mix.Task
  alias ExAtCoder.Repo

  def run([contest | tasks]) do
    Application.ensure_all_started(:hackney)

    filter =
      case tasks do
        [] -> fn _ -> true end
        _ -> fn {p, _} ->
          tasks |> Enum.map(&String.upcase/1) |> Enum.member?(p)
        end
      end

    Repo.contest_tasks(contest)
    |> Enum.filter(filter)
    |> Enum.each(fn {p, [url]} -> make_code(contest, p, url) end)

    Mix.shell().info("✨ Generate code for #{contest}")
    Mix.shell().info("👍 Good Luck")
  end

  defp make_code(contest, problem, url) do

    # ディレクトリ作成
    dir = "lib/#{contest}"
    unless File.exists?(dir) do
      Mix.Generator.create_directory(dir)
    end

    underscored_problem = Macro.underscore(problem)

    # 提出コード雛形作成
    file = dir <> "/#{underscored_problem}.ex"
    unless File.exists?(file) do
      namespace = "#{Macro.camelize(contest)}.#{Macro.camelize(underscored_problem)}"
      genenrate_code(file, namespace)
    end

    # テストケース
    testcase_dir = dir <> "/test_case"
    unless File.exists?(testcase_dir) do
      Mix.Generator.create_directory(testcase_dir)
    end

    yaml = testcase_dir <> "/#{underscored_problem}.yml"
    unless File.exists?(yaml) do
      cases =
        Repo.task_cases(url)
        |> Enum.map(&testcase_yaml/1)
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

  defp testcase_yaml({n, input_output}) when is_list(input_output) do

    input = Keyword.get(input_output, :input, "")
    output = Keyword.get(input_output, :output, "")

    """
    - name: sample#{n}
      in: |
    #{format_string(input)}
      out: |
    #{format_string(output)}
    """
  end

  defp format_string(str) when is_binary(str) do
    new_line_regex = ~r/\r|\n|\r\n/
    indent = "    "

    str
    |> String.split(new_line_regex)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(fn s -> indent <> s end)
    |> Enum.join("\n")
  end

end
