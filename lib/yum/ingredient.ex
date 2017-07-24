defmodule Yum.Ingredient do
    @moduledoc """
      A struct that contains all the data about an ingredient.
    """
    use Bitwise

    defstruct [
        ref: nil,
        translation: %{},
        exclude_diet: [],
        exclude_allergen: [],
        nutrition: %{}
    ]

    @type t :: %Yum.Ingredient{ ref: String.t, translation: Yum.Data.translation_tree, exclude_diet: [String.t], exclude_allergen: [String.t], nutrition: %{ optional(String.t) => any } }

    @doc """
      Flatten an ingredient tree into an ingredient list.

      Each item in the list can be safely operated on individually, as all of the
      data related to that item is inside of its struct (compared to the original
      tree where other data is inferred from its parent).
    """
    @spec new(Yum.Data.ingredient_tree) :: [t]
    def new(data), do: Enum.reduce(data, [], &new(&1, &2, %Yum.Ingredient{}))

    defp new({ key, value = %{ __info__: info } }, ingredients, group) do
        ingredient = %Yum.Ingredient{
            ref: "#{group.ref}/#{key}",
            translation: info["translation"] || %{}
        }
        |> new_exclude_diet(info, group)
        |> new_exclude_allergen(info, group)
        |> new_nutrition(info)

        [ingredient|Enum.reduce(value, ingredients, &new(&1, &2, ingredient))]
    end
    defp new(_, ingredients, _), do: ingredients

    defp new_exclude_diet(ingredient, %{ "exclude-diet" => diets }, parent), do: %{ ingredient | exclude_diet: Enum.uniq(diets ++ parent.exclude_diet) }
    defp new_exclude_diet(ingredient, _, parent), do: %{ ingredient | exclude_diet: parent.exclude_diet }

    defp new_exclude_allergen(ingredient, %{ "exclude-allergen" => allergens }, parent), do: %{ ingredient | exclude_allergen: Enum.uniq(allergens ++ parent.exclude_allergen) }
    defp new_exclude_allergen(ingredient, _, parent), do: %{ ingredient | exclude_allergen: parent.exclude_allergen }

    defp new_nutrition(ingredient, %{ "nutrition" => nutrition }), do: %{ ingredient | nutrition: nutrition }
    defp new_nutrition(ingredient, _), do: ingredient

    defp create_parent_ref([_|groups]), do: create_parent_ref(groups, "")

    defp create_parent_ref([_], ""), do: nil
    defp create_parent_ref([_], ref), do: ref
    defp create_parent_ref([current|groups], ref), do: create_parent_ref(groups, "#{ref}/#{current}")

    @doc """
      Get the parent ref.

      This can be used to either refer to the parent or find the parent.
    """
    @spec group_ref(t) :: String.t | nil
    def group_ref(%Yum.Ingredient{ ref: ref }) do
        String.split(ref, "/")
        |> create_parent_ref
    end

    @doc """
      Get the reference name of the ingredient.
    """
    @spec name(t) :: String.t
    def name(%Yum.Ingredient{ ref: ref }) do
        String.split(ref, "/")
        |> List.last
    end

    @doc """
      Get a hash of the ingredient's ref.

      This can be used to refer to this ingredient.

      __Note:__ This does not produce a hash representing the ingredient's current
      state.
    """
    @spec ref_hash(t, atom) :: binary
    def ref_hash(%Yum.Ingredient{ ref: ref }, algo \\ :sha), do: :crypto.hash(algo, ref)

    @encode_charset Enum.zip('abcdefghijklmnopqrstuvwxyz-/', 1..31)

    defp encode_ref(ref, encoding \\ <<>>)
    for { chr, index } <- @encode_charset do
        defp encode_ref(<<unquote(chr), ref :: binary>>, encoding), do: encode_ref(ref, <<encoding :: bitstring, unquote(index) :: size(5)>>)
    end
    defp encode_ref("", encoding), do: encoding

    defp decode_ref(encoding, ref \\ "")
    for { chr, index } <- @encode_charset do
        defp decode_ref(<<unquote(index) :: size(5), encoding :: bitstring>>, ref), do: decode_ref(encoding, ref <> unquote(<<chr>>))
    end
    defp decode_ref(<<>>, ref), do: ref
    defp decode_ref(<<0 :: size(5), _ :: bitstring>>, ref), do: ref

    @doc """
      Encode the ingredient's ref.

      This can be used to refer to this ingredient.
    """
    @spec ref_encode(t) :: bitstring
    def ref_encode(%Yum.Ingredient{ ref: ref }), do: encode_ref(ref)

    @doc """
      Decode the encoded ingredient reference.
    """
    @spec ref_decode(bitstring) :: String.t
    def ref_decode(ref), do: decode_ref(ref)
end
