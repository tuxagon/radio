defmodule Radio.ContextCache do
  alias Radio.Context

  @cache :context_cache

  @spec put(user_id :: String.t(), context :: Radio.Context.t()) :: {Cached.status(), boolean()}
  def put(user_id, %Context{} = context), do: Cachex.put(@cache, user_id, context)

  @spec get(user_id :: String.t()) :: {atom(), Radio.Context.t() | nil}
  def get(user_id), do: Cachex.get(@cache, user_id)

  @spec del(user_id :: String.t()) :: {Cached.status(), boolean()}
  def del(user_id), do: Cachex.del(@cache, user_id)
end
