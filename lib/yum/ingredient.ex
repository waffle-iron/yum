defmodule Yum.Ingredient do
    defstruct [
        ref: nil,
        translation: %{},
        exclude_diet: [],
        exclude_allergen: [],
        nutrition: %{}
    ]

    def new(data), do: Enum.reduce(data, [], &new(&1, &2, %Yum.Ingredient{}))

    defp new({ key, value = %{ __info__: info } }, ingredients, group) do
        ingredient = %Yum.Ingredient{
            ref: "#{group.ref}/#{key}",
            translation: info.translation
        }
        |> new_exclude_diet(info, group)
        |> new_exclude_allergen(value, group)
        |> new_nutrition(value)

        [ingredient|Enum.reduce(value, ingredients, &new(&1, &2, ingredient))]
    end
    defp new(_, ingredients, _), do: ingredients

    defp new_exclude_diet(ingredient, %{ "exclude-diet": diets }, parent), do: %{ ingredient | exclude_diet: Enum.uniq(diets ++ parent.exclude_diet) }
    defp new_exclude_diet(ingredient, _, parent), do: %{ ingredient | exclude_diet: parent.exclude_diet }

    defp new_exclude_allergen(ingredient, %{ "exclude-allergen": allergens }, parent), do: %{ ingredient | exclude_allergen: Enum.uniq(allergens ++ parent.exclude_allergen) }
    defp new_exclude_allergen(ingredient, _, parent), do: %{ ingredient | exclude_allergen: parent.exclude_allergen }

    defp new_nutrition(ingredient, %{ "nutrition": nutrition }), do: %{ ingredient | nutrition: nutrition }
    defp new_nutrition(ingredient, _), do: ingredient

    defp create_parent_ref([_|groups]), do: create_parent_ref(groups, "")

    defp create_parent_ref([_], ""), do: nil
    defp create_parent_ref([_], ref), do: ref
    defp create_parent_ref([current|groups], ref), do: create_parent_ref(groups, "#{ref}/#{current}")

    def group_ref(%Yum.Ingredient{ ref: ref }) do
        String.split(ref, "/")
        |> create_parent_ref
    end

    def name(%Yum.Ingredient{ ref: ref }) do
        String.split(ref, "/")
        |> List.last
    end
end
