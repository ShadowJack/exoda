defmodule Exoda.Query.Field do
  @moduledoc """
  Helper functions to work with individual fields
  """

  @doc """
  Build a full path to the field from the root source
  """
  @spec get_path({}, integer, String.t) :: String.t | no_return
  def get_path(_, 0, field_name), do: field_name
  def get_path(sources, idx, field_name) do
    # Build full path to the field that is stored in associated entry
    # Associated entries might be nested, ex.
    # ```
    # Advertisements?$filter=startswith(FeaturedProduct/ProductDetail/Details, 'Prod')
    # ```
    #TODO: validate that join is made through fields that are in assoc
    {_, source_schema} = elem(sources, 0)
    {_, target_schema} = elem(sources, idx)
    case Exoda.Query.Select.find_associations_path(source_schema, target_schema) do
      [] -> 
        raise "Association path from #{source_schema} to #{target_schema} is not found"
      path ->  
        "#{Enum.join(path, "/")}/#{field_name}"
    end
  end
end
