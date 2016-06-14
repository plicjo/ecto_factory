defmodule EctoFactory do
  @moduledoc """
  ## Create structs and insert data from your Ecto schemas.

  ### How to use:
  Define your factories in your config:

  ```
  config :ecto_factory, factories: [
    user: User,
    default_user: { User },

    user_with_default_username: { User,
      username: "mrmicahcooper"
    }
  ]
  ```
  """

  @models Application.get_env(:ecto_factory, :factories)

  @doc """
  Create a struct of the passed in user type

  iex> EctoFactory.build(:user)
  %User{
    age: 1,
    username: "username",
    date_of_birth: Ecto.DateTime.utc
  }

  iex> EctoFactory.build(:user_with_default_username)
  %User{
    age: 1,
    username: "mrmicahcooper",
    date_of_birth: Ecto.DateTime.utc
  }
  """
  def build(model_name, attrs \\ %{}) do
    {model, attrs} = build_attrs(model_name, attrs)
    struct(model, attrs)
  end

  defp build_attrs(model_name, attrs) do
    model  = model(model_name)
    attributes  = model.__changeset__
                  |> remove_primary_key(model)
                  |> Enum.map(&build_value/1)
                  |> Map.new()
                  |> apply_defaults(model_name)
                  |> Map.merge(Map.new(attrs))
    { model, attributes }
  end

  defp model(model_name) do
    case @models[model_name] do
      {model, _} -> model
      {model}    -> model
      model      -> model
    end
  end

  defp apply_defaults(map, model_name) do
    attrs = case @models[model_name] do
      {model, attrs} -> attrs |> Map.new()
      _else          -> %{}
    end
    Map.merge(map, attrs)
  end

  defp remove_primary_key(model_map, model) do
    case model.__schema__(:autogenerate_id) do
      {primary_key, _} -> Map.delete(model_map, primary_key)
      _else            -> model_map
    end
  end

  defp build_value({key, :string}),      do: {key, Atom.to_string(key)}
  defp build_value({key, :integer}),     do: {key, 1}
  defp build_value({key, {:assoc, _}}),  do: {key, []}
  defp build_value({key, Ecto.DateTime}) do
    {key, Ecto.DateTime.cast!(:calendar.universal_time) }
  end

  defp build_value({key, value}), do: {key, nil}

end