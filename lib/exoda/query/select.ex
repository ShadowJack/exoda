defmodule Exoda.Query.Select do
  alias Ecto.Query
  alias Ecto.Query.SelectExpr

  @moduledoc """
  Helpers to build $select and $expand parameters for OData query expression
  """


  defstruct expand_name: nil, schema: nil, selects: [], expands: []
  @type relations_tree :: %__MODULE__{expand_name: String.t, schema: atom, selects: [String.t], expands: [relations_tree]}
  @typep sources :: {}
  

  @doc """
  Update `query_string_params` collection with $select and $expand parameters
  """
  @spec add_select(Map.t, Query.t) :: Map.t
  def add_select(query_string_params, %Query{select: %SelectExpr{expr: {:&, _, _}}}) do
    # select full entity - don't have to add $select
    # TODO: can potentially select from association but not from the main schema
    query_string_params
  end
  def add_select(query_string_params, %Query{select: %SelectExpr{fields: fields}, sources: sources}) do
    sel =
      sources
      |> build_relations_tree(fields)
      |> convert_relations_tree_to_querystring()
    case sel do
      "$select=" <> rest -> 
        Map.put(query_string_params, "$select", rest)
      "" ->
        Map.put(query_string_params, "$select", "")
    end
  end

  @doc """
  Converts a tuple of sources into a relations tree
  """
  @spec build_relations_tree(sources, []) :: relations_tree
  def build_relations_tree(sources, fields) do
    {_, main_schema} = elem(sources, 0)
    sources_list = sources |> Tuple.to_list() |> Enum.map(fn {_, module} -> module end)
    initial_tree =  %__MODULE__{
      expand_name: "",
      schema: main_schema
    }
    do_build_relations_tree([main_schema], sources_list, fields, [], initial_tree)
  end

  @doc """
  Build an OData query string from relations tree using DFS
  """
  @spec convert_relations_tree_to_querystring(relations_tree) :: String.t
  def convert_relations_tree_to_querystring(relations) do
    case Enum.join(relations.selects, ",") do
      "" -> ""
      fields -> 
        result = "$select=#{fields}"
        if length(relations.expands) > 0 do
          expands_queries = 
            relations.expands
            |> Enum.map(fn exp ->
              selects = convert_relations_tree_to_querystring(exp)
              "#{exp.expand_name}(#{selects})"
            end)
            |> Enum.join(",")
          result <> "&$expand=#{expands_queries}"
        else
          result
        end
    end
  end

  # Build a tree traversing associations in BFS order
  @spec do_build_relations_tree([atom], [atom], [], [atom], relations_tree) :: relations_tree
  defp do_build_relations_tree([], _, _, _, result), do: result
  defp do_build_relations_tree([curr_schema | tail], sources, fields, visited, result) do
    # add expands
    assocs = extract_assocs(curr_schema, visited, sources)
    updated_result = put_expands(result, curr_schema, assocs)

    # add selects
    curr_fields = 
      fields 
      |> Enum.map(fn {{:., _, [{:&, _, [idx]}, field_name]}, _, _} -> {idx, field_name} end)
      |> Enum.filter(fn {idx, _} -> Enum.at(sources, idx) == curr_schema end)
      |> Enum.map(fn {_, field_name} -> field_name end)
    updated_result = put_selects(updated_result, curr_schema, curr_fields)

    assocs_mods = Enum.map(assocs, fn {_, s} -> s end)
    do_build_relations_tree(tail ++ assocs_mods, sources, fields, [curr_schema | visited], updated_result)
  end

  defp extract_assocs(curr_schema, visited, sources) do
    curr_schema.__schema__(:associations) 
    |> Enum.map(fn assoc_name -> curr_schema.__schema__(:association, assoc_name) end)
    |> Enum.filter(fn assoc -> is_tuple(assoc.queryable) end)
    |> Enum.map(fn %{queryable: {field, schema}} -> {field, schema} end)
    |> Enum.reject(fn {_, schema} -> 
      Enum.any?(visited, &(&1 == schema)) || !Enum.any?(sources, &(&1 == schema)) 
    end)
  end

  # Insert new assocs into the relations tree using DFS
  defp put_expands(%__MODULE__{schema: curr_schema} = result, target, assocs) when curr_schema == target do
    # add all assocs as children expands
    new_expands = assocs |> Enum.map(fn 
      {field, schema} -> %__MODULE__{expand_name: field, schema: schema, expands: []} 
    end)
    %{result | expands: new_expands}
  end
  defp put_expands(%__MODULE__{expands: expands} = result, target, assocs) do
    updated_expands = expands |> Enum.map(&put_expands(&1, target, assocs))
    %{result | expands: updated_expands}
  end

  # Insert fields to be selected from `curr_schema` into the relations tree
  defp put_selects(%__MODULE__{schema: curr_schema} = result, target, fields) when curr_schema == target do
    %{result | selects: fields}
  end
  defp put_selects(%__MODULE__{expands: expands} = result, target, fields) do
    updated_expands = expands |> Enum.map(&put_selects(&1, target, fields))
    %{result | expands: updated_expands}
  end
end