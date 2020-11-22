defmodule Mix.Tasks.Atcoder.New do
  @shortdoc "指定されたコンテストの問題の雛形を作成します"

  use Mix.Task
  alias ExAtcoder.HttpClient

  @base_url "https://atcoder.jp"
  @contest_url @base_url <> "/contests"

  def run([contest | _t]) do
    Application.ensure_all_started(:hackney)

    IO.inspect("#{@contest_url}/#{contest}/tasks")
    body = HttpClient.get("#{@contest_url}/#{contest}/tasks")

    body
    |> Floki.parse_document!()
    |> Floki.find("table")
    |> Floki.find("tr > td:nth-child(1) > a")
    |> Enum.map(fn tag -> {Floki.text(tag), Floki.attribute(tag, "href")} end)
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
      body = HttpClient.get(@base_url <> url)
      cases =
        Floki.parse_document!(body)
        |> Floki.find(".part > section")
        |> extract_sample()
        |> Enum.map(fn {n, [input: input, output: output]} ->
          """
          - name: sample#{n}
            in: |
              #{String.replace(input, "\r\n", "\n    ")}
            out: |
              #{String.replace(output, "\r\n", "\n    ")}
          """
        end)
        |> Enum.join("\n")

      File.write!(yaml, cases)

      IO.puts("#{yaml} create ✨")
    end

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

defmodule CodeTemplate do
  require EEx
  EEx.function_from_file(:def, :make, "lib/template.eex", [:namespace])
end
