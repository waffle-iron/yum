defmodule Yum.IngredientTest do
    use ExUnit.Case

    setup do
        %{
            ingredients: %{
                "one" => %{
                    :__info__ => %{},
                    "foo" => %{
                        :__info__ => %{
                            "translation" => %{ "en" => %{ "term" => "1" } },
                            "exclude-diet" => ["c", "d"],
                            "exclude-allergen" => ["C", "D"],
                            "nutrition" => %{ "foobar" => "5" }
                        },
                        "bar-a" => %{ :__info__ => %{} },
                        "bar-b" => %{ :__info__ => %{ "exclude-diet" => ["e"], "exclude-allergen" => ["E"] } },
                        "bar-c" => %{
                            :__info__ => %{ "nutrition" => %{ "foobar" => "6" } },
                            "test" => %{ :__info__ => %{} }
                        }
                    }
                },
                "two" => %{},
                "three" => %{
                    :__info__ => %{
                        "translation" => %{ "en" => %{ "term" => "2" } },
                        "exclude-diet" => ["a", "b"],
                        "exclude-allergen" => ["A", "B"]
                    },
                    "foo" => %{
                        :__info__ => %{
                            "translation" => %{ "en" => %{ "term" => "1" } },
                            "exclude-diet" => ["c", "d"],
                            "exclude-allergen" => ["C", "D"],
                            "nutrition" => %{ "foobar" => "5" }
                        },
                        "bar-a" => %{ :__info__ => %{} },
                        "bar-b" => %{ :__info__ => %{ "exclude-diet" => ["e"], "exclude-allergen" => ["E"] } },
                        "bar-c" => %{
                            :__info__ => %{ "nutrition" => %{ "foobar" => "6" } },
                            "test" => %{ :__info__ => %{} }
                        }
                    }
                }
            }
        }
    end

    test "new/1", %{ ingredients: ingredients } do
        assert [
            %Yum.Ingredient{ ref: "/one" },
            %Yum.Ingredient{ ref: "/one/foo", translation: %{ "en" => %{ "term" => "1" } }, exclude_diet: ["c", "d"], exclude_allergen: ["C", "D"], nutrition: %{ "foobar" => "5" } },
            %Yum.Ingredient{ ref: "/one/foo/bar-a", exclude_diet: ["c", "d"], exclude_allergen: ["C", "D"] },
            %Yum.Ingredient{ ref: "/one/foo/bar-b", exclude_diet: ["e", "c", "d"], exclude_allergen: ["E", "C", "D"] },
            %Yum.Ingredient{ ref: "/one/foo/bar-c", exclude_diet: ["c", "d"], exclude_allergen: ["C", "D"], nutrition: %{ "foobar" => "6" } },
            %Yum.Ingredient{ ref: "/one/foo/bar-c/test", exclude_diet: ["c", "d"], exclude_allergen: ["C", "D"] },
            %Yum.Ingredient{ ref: "/three", translation: %{ "en" => %{ "term" => "2" } }, exclude_diet: ["a", "b"], exclude_allergen: ["A", "B"] },
            %Yum.Ingredient{ ref: "/three/foo", translation: %{ "en" => %{ "term" => "1" } }, exclude_diet: ["c", "d", "a", "b"], exclude_allergen: ["C", "D", "A", "B"], nutrition: %{ "foobar" => "5" } },
            %Yum.Ingredient{ ref: "/three/foo/bar-a", exclude_diet: ["c", "d", "a", "b"], exclude_allergen: ["C", "D", "A", "B"] },
            %Yum.Ingredient{ ref: "/three/foo/bar-b", exclude_diet: ["e", "c", "d", "a", "b"], exclude_allergen: ["E", "C", "D", "A", "B"] },
            %Yum.Ingredient{ ref: "/three/foo/bar-c", exclude_diet: ["c", "d", "a", "b"], exclude_allergen: ["C", "D", "A", "B"], nutrition: %{ "foobar" => "6" } },
            %Yum.Ingredient{ ref: "/three/foo/bar-c/test", exclude_diet: ["c", "d", "a", "b"], exclude_allergen: ["C", "D", "A", "B"] }
        ] == Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref))

        assert [] == Yum.Ingredient.new(%{})
        assert [%Yum.Ingredient{ ref: "/test" }] == Yum.Ingredient.new(ingredients["three"]["foo"]["bar-c"])
    end

    test "name/1", %{ ingredients: ingredients } do
        assert [
            "one",
            "foo",
            "bar-a",
            "bar-b",
            "bar-c",
            "test",
            "three",
            "foo",
            "bar-a",
            "bar-b",
            "bar-c",
            "test"
        ] == Enum.map(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)), &Yum.Ingredient.name/1)

        assert ["test"] == Enum.map(Yum.Ingredient.new(ingredients["three"]["foo"]["bar-c"]), &Yum.Ingredient.name/1)
    end

    test "group_ref/1", %{ ingredients: ingredients } do
        assert [
            nil,
            "/one",
            "/one/foo",
            "/one/foo",
            "/one/foo",
            "/one/foo/bar-c",
            nil,
            "/three",
            "/three/foo",
            "/three/foo",
            "/three/foo",
            "/three/foo/bar-c",
        ] == Enum.map(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)), &Yum.Ingredient.group_ref/1)

        assert [nil] == Enum.map(Yum.Ingredient.new(ingredients["three"]["foo"]["bar-c"]), &Yum.Ingredient.group_ref/1)
    end

    test "ref_hash/2", %{ ingredients: ingredients } do
        assert 12 == Enum.count(Enum.uniq(Enum.map(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)), &Yum.Ingredient.ref_hash/1)))

        ingredient_test = List.last(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)))

        assert [Yum.Ingredient.ref_hash(ingredient_test)] != Enum.map(Yum.Ingredient.new(ingredients["three"]["foo"]["bar-c"]), &Yum.Ingredient.group_ref/1)
        assert Yum.Ingredient.ref_hash(ingredient_test) == Yum.Ingredient.ref_hash(%{ ingredient_test | translation: %{ "en" => %{ "term" => "1" } } })
    end

    test "ref_encode/2", %{ ingredients: ingredients } do
        assert 12 == Enum.count(Enum.uniq(Enum.map(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)), &Yum.Ingredient.ref_encode/1)))

        ingredient_test = List.last(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)))

        assert [Yum.Ingredient.ref_encode(ingredient_test)] != Enum.map(Yum.Ingredient.new(ingredients["three"]["foo"]["bar-c"]), &Yum.Ingredient.group_ref/1)
        assert Yum.Ingredient.ref_encode(ingredient_test) == Yum.Ingredient.ref_encode(%{ ingredient_test | translation: %{ "en" => %{ "term" => "1" } } })

        assert [
            "/one",
            "/one/foo",
            "/one/foo/bar-a",
            "/one/foo/bar-b",
            "/one/foo/bar-c",
            "/one/foo/bar-c/test",
            "/three",
            "/three/foo",
            "/three/foo/bar-a",
            "/three/foo/bar-b",
            "/three/foo/bar-c",
            "/three/foo/bar-c/test"
        ] == Enum.map(Enum.map(Enum.sort(Yum.Ingredient.new(ingredients), &(&1.ref < &2.ref)), &Yum.Ingredient.ref_encode/1), &Yum.Ingredient.ref_decode/1)
    end
end
