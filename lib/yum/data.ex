defmodule Yum.Data do
    @moduledoc """
      Import food data.
    """
    @type translation :: %{ optional(String.t) => translation | String.t }
    @type translation_tree :: %{ optional(String.t) => translation }
    @type diet_list :: [String.t]
    @type allergen_list :: [String.t]
    @type nutrition :: %{ optional(String.t) => any }
    @type ingredient_tree :: %{ optional(String.t) => ingredient_tree, required(:__info__) => %{ optional(String.t) => translation_tree | diet_list | allergen_list | nutrition } }
    @type cuisine_tree :: %{ optional(String.t) => cuisine_tree, required(:__info__) => %{ optional(String.t) => translation_tree | nutrition } }

    defp load(path), do: TomlElixir.parse_file!(path)

    @path "data/Food-Data"

    @doc """
      Load the diet names and translations.
    """
    @spec diets(String.t) :: translation_tree
    def diets(data \\ @path), do: load(Path.join(data, "translations/diet-names.toml"))

    @doc """
      Load the allergen names and translations.
    """
    @spec allergens(String.t) :: translation_tree
    def allergens(data \\ @path), do: load(Path.join(data, "translations/allergen-names.toml"))

    @doc """
      Load the ingredient data.
    """
    @spec ingredients(String.t) :: ingredient_tree
    def ingredients(group \\ "", data \\ @path), do: load_tree(Path.join([data, "ingredients", group]))

    @doc """
      Load the cuisine data.
    """
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
