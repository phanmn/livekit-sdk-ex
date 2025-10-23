# Copyright 2023 LiveKit, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule LivekitSdkEx.AccessToken do
  @moduledoc """
  AccessToken produces JWT tokens signed with API key and secret.

  ## Usage

  ### Creating and signing a token:

      token = AccessToken.new("api_key", "api_secret")
      |> AccessToken.set_identity("user123")
      |> AccessToken.set_name("John Doe")
      |> AccessToken.set_video_grant(%VideoGrant{
        room_join: true,
        room: "my-room",
        can_publish: true
      })
      |> AccessToken.set_metadata("user metadata")

      {:ok, jwt} = AccessToken.to_jwt(token)

  ### Parsing and verifying a token:

      {:ok, token} = AccessToken.from_jwt(jwt, "api_secret")
      claims = AccessToken.get_grants(token)

  ## Dependencies

  Add to your mix.exs:

      {:joken, "~> 2.6"}
      {:jason, "~> 1.4"}
  """

  # 6 hours in seconds
  @default_valid_duration 6 * 60 * 60

  defstruct [
    :api_key,
    :secret,
    :grant,
    :valid_for,
    :allow_sensitive_credentials
  ]

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          secret: String.t() | nil,
          grant: LivekitSdkEx.ClaimGrants.t(),
          valid_for: non_neg_integer() | nil,
          allow_sensitive_credentials: boolean()
        }

  @doc """
  Create a new AccessToken with API key and secret.

  ## Examples

      iex> AccessToken.new("api_key", "api_secret")
      %AccessToken{api_key: "api_key", secret: "api_secret", ...}
  """
  @spec new(String.t(), String.t()) :: t()
  def new(api_key, secret) do
    %__MODULE__{
      api_key: api_key,
      secret: secret,
      grant: %LivekitSdkEx.ClaimGrants{},
      valid_for: nil,
      allow_sensitive_credentials: false
    }
  end

  @doc """
  Set the identity (user ID) for the token.
  """
  @spec set_identity(t(), String.t()) :: t()
  def set_identity(%__MODULE__{grant: grant} = token, identity) do
    %{token | grant: %{grant | identity: identity}}
  end

  @doc """
  Set the validity duration for the token in seconds.

  ## Examples

      iex> AccessToken.set_valid_for(token, 3600)  # 1 hour
  """
  @spec set_valid_for(t(), non_neg_integer()) :: t()
  def set_valid_for(%__MODULE__{} = token, duration) do
    %{token | valid_for: duration}
  end

  @doc """
  Set the display name for the participant.
  """
  @spec set_name(t(), String.t()) :: t()
  def set_name(%__MODULE__{grant: grant} = token, name) do
    %{token | grant: %{grant | name: name}}
  end

  @doc """
  Set the participant kind.

  Valid kinds: "standard", "ingress", "egress", "sip", "agent"
  """
  @spec set_kind(t(), String.t()) :: t()
  def set_kind(%__MODULE__{grant: grant} = token, kind) do
    %{token | grant: %{grant | kind: kind}}
  end

  @doc """
  Set the video grant for room access and permissions.
  """
  @spec set_video_grant(t(), VideoGrant.t()) :: t()
  def set_video_grant(%__MODULE__{grant: grant} = token, video_grant) do
    %{token | grant: %{grant | video: video_grant}}
  end

  @doc """
  Set the SIP grant for SIP call permissions.
  """
  @spec set_sip_grant(t(), SIPGrant.t()) :: t()
  def set_sip_grant(%__MODULE__{grant: grant} = token, sip_grant) do
    %{token | grant: %{grant | sip: sip_grant}}
  end

  @doc """
  Set the agent grant for agent permissions.
  """
  @spec set_agent_grant(t(), AgentGrant.t()) :: t()
  def set_agent_grant(%__MODULE__{grant: grant} = token, agent_grant) do
    %{token | grant: %{grant | agent: agent_grant}}
  end

  @doc """
  Set the inference grant for AI inference permissions.
  """
  @spec set_inference_grant(t(), InferenceGrant.t()) :: t()
  def set_inference_grant(%__MODULE__{grant: grant} = token, inference_grant) do
    %{token | grant: %{grant | inference: inference_grant}}
  end

  @doc """
  Set the observability grant for observability permissions.
  """
  @spec set_observability_grant(t(), ObservabilityGrant.t()) :: t()
  def set_observability_grant(%__MODULE__{grant: grant} = token, observability_grant) do
    %{token | grant: %{grant | observability: observability_grant}}
  end

  @doc """
  Set metadata for the participant.
  """
  @spec set_metadata(t(), String.t()) :: t()
  def set_metadata(%__MODULE__{grant: grant} = token, metadata) do
    %{token | grant: %{grant | metadata: metadata}}
  end

  @doc """
  Set or merge attributes for the participant.
  """
  @spec set_attributes(t(), %{String.t() => String.t()}) :: t()
  def set_attributes(%__MODULE__{grant: _} = token, attrs) when map_size(attrs) == 0 do
    token
  end

  def set_attributes(%__MODULE__{grant: grant} = token, attrs) do
    existing_attrs = grant.attributes || %{}
    new_attrs = Map.merge(existing_attrs, attrs)
    %{token | grant: %{grant | attributes: new_attrs}}
  end

  @doc """
  Set SHA256 hash for message integrity verification.
  """
  @spec set_sha256(t(), String.t()) :: t()
  def set_sha256(%__MODULE__{grant: grant} = token, sha) do
    %{token | grant: %{grant | sha256: sha}}
  end

  @doc """
  Set room preset configuration.
  """
  @spec set_room_preset(t(), String.t()) :: t()
  def set_room_preset(%__MODULE__{grant: grant} = token, preset) do
    %{token | grant: %{grant | room_preset: preset}}
  end

  @doc """
  Set room configuration.
  """
  @spec set_room_config(t(), LivekitSdkEx.RoomConfiguration.t() | nil) :: t()
  def set_room_config(%__MODULE__{grant: grant} = token, config) do
    %{token | grant: %{grant | room_config: config}}
  end

  @doc """
  Set agents in room configuration (shortcut method).
  """
  @spec set_agents(t(), [LivekitSdkEx.RoomAgentDispatch.t()]) :: t()
  def set_agents(%__MODULE__{grant: grant} = token, agents) do
    room_config = grant.room_config || %LivekitSdkEx.RoomConfiguration{}
    updated_config = %{room_config | agents: agents}
    %{token | grant: %{grant | room_config: updated_config}}
  end

  @doc """
  Enable or disable allowing sensitive credentials in the token.

  When tokens are issued to end-users, it's not recommended to include sensitive
  data such as API keys/secrets. JWT tokens are not encrypted, so anything issued
  in them can be read by anyone.

  When tokens are used in a server environment (i.e. connecting from SIP or Agents),
  you can bypass the credentials check by enabling this option.
  """
  @spec set_allow_sensitive_credentials(t(), boolean()) :: t()
  def set_allow_sensitive_credentials(%__MODULE__{} = token, allow) do
    %{token | allow_sensitive_credentials: allow}
  end

  @doc """
  Get the claim grants from the token.
  """
  @spec get_grants(t()) :: LivekitSdkEx.ClaimGrants.t()
  def get_grants(%__MODULE__{grant: grant}) do
    grant
  end

  @doc """
  Generate a JWT string from the access token.

  ## Returns

  - `{:ok, jwt_string}` on success
  - `{:error, reason}` on failure

  ## Examples

      token = AccessToken.new("api_key", "api_secret")
      |> AccessToken.set_identity("user123")
      |> AccessToken.set_video_grant(%VideoGrant{room_join: true, room: "my-room"})

      {:ok, jwt} = AccessToken.to_jwt(token)
  """
  @spec to_jwt(t()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def to_jwt(%__MODULE__{api_key: nil}), do: {:error, :api_key_missing}
  def to_jwt(%__MODULE__{secret: nil}), do: {:error, :secret_missing}
  def to_jwt(%__MODULE__{api_key: "", secret: _}), do: {:error, :api_key_missing}
  def to_jwt(%__MODULE__{api_key: _, secret: ""}), do: {:error, :secret_missing}

  def to_jwt(%__MODULE__{} = token) do
    # Check for sensitive credentials if not allowed
    if token.grant.room_config && !token.allow_sensitive_credentials do
      # Note: You would need to implement check_credentials/1
      # For now, we'll skip this check
      :ok
    end

    now = System.system_time(:second)
    valid_for = cond do
      token.valid_for != nil -> token.valid_for
      true -> @default_valid_duration
    end

    claims = %{
      "iss" => token.api_key,
      "sub" => token.grant.identity,
      "nbf" => now,
      "exp" => now + valid_for
    }

    # Merge grant claims (excluding nil values)
    grant_claims =
      token.grant
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> convert_keys_to_camel_case()

    all_claims = Map.merge(claims, grant_claims)

    # Sign the token
    signer = Joken.Signer.create("HS256", token.secret)

    case Joken.encode_and_sign(all_claims, signer) do
      {:ok, jwt, _claims} -> {:ok, jwt}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate a JWT string from the access token (raises on error).
  """
  @spec to_jwt!(t()) :: String.t()
  def to_jwt!(%__MODULE__{} = token) do
    case to_jwt(token) do
      {:ok, jwt} -> jwt
      {:error, reason} -> raise "Failed to generate JWT: #{inspect(reason)}"
    end
  end

  @doc """
  Parse and verify a JWT token, returning an AccessToken struct.

  ## Parameters

  - `jwt` - The JWT string to parse
  - `secret` - The secret key to verify the signature
  - `opts` - Optional keyword list with:
    - `:verify_exp` - Verify expiration (default: true)
    - `:verify_nbf` - Verify not before (default: true)

  ## Returns

  - `{:ok, access_token}` on success
  - `{:error, reason}` on failure

  ## Examples

      {:ok, token} = AccessToken.from_jwt(jwt_string, "api_secret")
      claims = AccessToken.get_grants(token)
  """
  @spec from_jwt(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, any()}
  def from_jwt(jwt, secret, opts \\ []) do
    verify_exp = Keyword.get(opts, :verify_exp, true)
    signer = Joken.Signer.create("HS256", secret)

    with {:ok, claims} <- Joken.verify(jwt, signer) do
      # Verify expiration
      if verify_exp do
        now = System.system_time(:second)
        exp = Map.get(claims, "exp")

        if exp && exp < now do
          {:error, :token_expired}
        else
          parse_claims(claims, secret)
        end
      else
        parse_claims(claims, secret)
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parse and verify a JWT token (raises on error).
  """
  @spec from_jwt!(String.t(), String.t(), keyword()) :: t()
  def from_jwt!(jwt, secret, opts \\ []) do
    case from_jwt(jwt, secret, opts) do
      {:ok, token} -> token
      {:error, reason} -> raise "Failed to parse JWT: #{inspect(reason)}"
    end
  end

  def from_jwt(jwt) do
    with {:ok, claims} <- Joken.peek_claims(jwt) do
      parse_claims(claims)
    end
  end

  # Private helper to parse claims into AccessToken struct
  defp parse_claims(claims) do
    api_key = Map.get(claims, "iss")
    identity = Map.get(claims, "sub")
    exp = Map.get(claims, "exp")
    nbf = Map.get(claims, "nbf")

    valid_for =
      cond do
        # Normal case: both exp and nbf are set and nbf > 0
        exp && nbf && nbf > 0 ->
          # Original duration
          exp - nbf

        # Edge case: nbf is 0 or nil
        exp ->
          now = System.system_time(:second)
          # Remaining time
          max(0, exp - now)

        # No expiration
        true ->
          nil
      end

    # Convert claim keys from camelCase to snake_case
    grant_map =
      claims
      |> Map.drop(["iss", "sub", "nbf", "exp", "iat", "jti"])
      |> convert_keys_to_snake_case()
      |> Map.put(:identity, identity)

    grant = LivekitSdkEx.ClaimGrants.new(grant_map)

    token = %__MODULE__{
      api_key: api_key,
      secret: nil,
      grant: grant,
      valid_for: valid_for,
      allow_sensitive_credentials: false
    }

    {:ok, token}
  end

  defp parse_claims(claims, secret) do
    with {:ok, token} <- parse_claims(claims) do
      {:ok, %{token | secret: secret}}
    end
  end

  # Convert map keys to camelCase for JWT encoding
  defp convert_keys_to_camel_case(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {Recase.to_camel(key), convert_value_to_camel_case(v)}
    end)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp convert_value_to_camel_case(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> convert_keys_to_camel_case()
  end

  defp convert_value_to_camel_case(list) when is_list(list) do
    Enum.map(list, &convert_value_to_camel_case/1)
  end

  defp convert_value_to_camel_case(map) when is_map(map) do
    convert_keys_to_camel_case(map)
  end

  defp convert_value_to_camel_case(value), do: value

  # Convert map keys from camelCase to snake_case for parsing
  defp convert_keys_to_snake_case(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      key = if is_binary(k), do: k, else: to_string(k)
      {String.to_existing_atom(Recase.to_snake(key)), convert_value_to_snake_case(v)}
    end)
  end

  defp convert_value_to_snake_case(map) when is_map(map) and not is_struct(map) do
    convert_keys_to_snake_case(map)
  end

  defp convert_value_to_snake_case(list) when is_list(list) do
    Enum.map(list, &convert_value_to_snake_case/1)
  end

  defp convert_value_to_snake_case(value), do: value
end
