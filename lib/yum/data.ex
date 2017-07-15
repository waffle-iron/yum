defmodule Yum.Data do
    defp load(path), do: File.read!(path) |> Tomlex.load

    @path "data/Food-Data"
    def diets(data \\ @path), do: load(Path.join(data, "translations/diet-names.toml"))

    def allergens(data \\ @path), do: load(Path.join(data, "translations/allergen-names.toml"))

    def ingredients(group \\ "", data \\ @path), do: load_tree(Path.join([data, "ingredients", group]))

    def cuisines(group \\ "", data \\ @path), do: load_tree(Path.join([data, "cuisines", group]))

    defp load_tree(path) do
        Path.wildcard(Path.join(path, "**/*.toml"))
        |> Enum.reduce(%{}, fn file, acc ->
            [_|paths] = Enum.reverse(Path.split(Path.relative_to(file, path)))
            contents = Enum.reduce([Path.basename(file, ".toml")|paths], %{ __info__: load(file) }, fn name, contents ->
                %{ name => contents }
            end)

            Map.merge(acc, contents, &merge_nested_contents/3)
        end)
    end

    defp merge_nested_contents(_key, a, b), do: Map.merge(a, b, &merge_nested_contents/3)
end
