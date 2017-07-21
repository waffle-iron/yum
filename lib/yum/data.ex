defmodule Yum.Data do
    @type translation :: %{ optional(:term) => String.t, optional(:adj) => String.t, optional(atom) => translation }
    @type translation_tree :: %{ optional(atom) => translation }
    @type ingredient_tree :: %{ optional(String.t) => ingredient_tree, optional(:__info__) => %{ optional(:translation) => translation_tree, optional(:"exclude-diet") => [String.t], optional(:"exclude-allergen") => [String.t], optional(:nutrition) => %{ optional(atom) => any } } }
    @type cuisine_tree :: %{ optional(String.t) => cuisine_tree, optional(:__info__) => %{ optional(:translation) => translation_tree, optional(:nutrition) => %{ optional(atom) => any } } }

    defp load(path), do: File.read!(path) |> Tomlex.load

    @path "data/Food-Data"

    @spec diets(String.t) :: translation_tree
    def diets(data \\ @path), do: load(Path.join(data, "translations/diet-names.toml"))

    @spec allergens(String.t) :: translation_tree
    def allergens(data \\ @path), do: load(Path.join(data, "translations/allergen-names.toml"))

    @spec ingredients(String.t) :: ingredient_tree
    def ingredients(group \\ "", data \\ @path), do: load_tree(Path.join([data, "ingredients", group]))

    @spec cuisines(String.t) :: cuisine_tree
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
