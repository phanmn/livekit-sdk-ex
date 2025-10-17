defmodule LivekitSdkEx.AccessToken do
  @moduledoc """
  Handles generation and management of Livekit access tokens.
  """

  alias LivekitSdkEx.Grants

  defstruct api_key: nil,
            api_secret: nil,
            grants: %Grants{},
            identity: nil,
            name: nil,
            ttl: nil,
            metadata: nil

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          api_secret: String.t() | nil,
          grants: Grants.t(),
          identity: String.t() | nil,
          name: String.t() | nil,
          ttl: integer() | nil,
          metadata: String.t() | nil
        }

  @doc """
  Creates a new AccessToken with the given API key and secret.
  """
  def new(api_key, api_secret) do
    %__MODULE__{
      api_key: api_key,
      api_secret: api_secret
    }
  end

  @doc """
  Sets the identity for the token.
  """
  def with_identity(%__MODULE__{} = token, identity) do
    %{token | identity: identity}
  end

  @doc """
  Sets the TTL (time to live) for the token in seconds.
  """
  def with_ttl(%__MODULE__{} = token, ttl) when is_integer(ttl) do
    %{token | ttl: ttl}
  end

  @doc """
  Sets metadata for the token.
  """
  def with_metadata(%__MODULE__{} = token, metadata) do
    %{token | metadata: metadata}
  end

  @doc """
  Sets the name for the token.
  """
  def with_name(%__MODULE__{} = token, name) do
    %{token | name: name}
  end

  @doc """
  Sets the grants for the token.
  """
  def with_grants(%__MODULE__{} = token, %Grants{} = grants) do
    %{token | grants: grants}
  end

  @doc """
  Adds a grant to the token.
  """
  def add_grant(%__MODULE__{} = token, grant) do
    %{token | grants: Map.merge(token.grants, grant)}
  end

  @doc """
  Generates a JWT token string.
  """
  def to_jwt(%__MODULE__{} = token) do
    current_time = System.system_time(:second)
    exp_time = current_time + (token.ttl || 3600)

    video_grant =
      token.grants
      |> Map.from_struct()
      |> Enum.map(fn {k, v} -> {Recase.to_camel(to_string(k)), v} end)
      |> Enum.into(%{})

    claims = %{
      "iss" => token.api_key,
      "sub" => token.identity,
      "nbf" => current_time,
      "exp" => exp_time,
      "video" => video_grant,
      "metadata" => token.metadata,
      "name" => token.name || token.identity
    }

    signer = Joken.Signer.create("HS256", token.api_secret)
    {:ok, jwt, _claims} = Joken.encode_and_sign(claims, signer)
    jwt
  end

  @doc """
  Creates an AccessToken struct from a JWT token string without verification.

  This function decodes the JWT token without verifying its signature.
  Use this when you want to inspect the token contents without validation,
  or when you don't have the API secret available.

  ## Parameters

  - `jwt`: The JWT token string to decode

  ## Returns

  - `{:ok, %AccessToken{}}`: If the token can be decoded, returns the AccessToken struct
  - `{:error, reason}`: If the token cannot be decoded

  ## Examples

      iex> AccessToken.from_jwt(jwt_string)
      {:ok, %AccessToken{identity: "user123", ...}}

  ## Note

  The returned AccessToken will have `api_secret` set to nil since the token
  is not verified. The `api_key` will be extracted from the token's "iss" claim.
  """
  @spec from_jwt(String.t()) :: {:ok, t()} | {:error, any()}
  def from_jwt(jwt) when is_binary(jwt) do
    case Joken.peek_claims(jwt) do
      {:ok, claims} ->
        # Calculate TTL from exp claim
        current_time = System.system_time(:second)
        exp_time = claims["exp"]
        ttl = if exp_time, do: max(0, exp_time - current_time), else: nil

        # Convert video grants from camelCase to snake_case
        grants = parse_video_grants(claims["video"])

        token = %__MODULE__{
          api_key: claims["iss"],
          api_secret: nil,
          identity: claims["sub"],
          name: claims["name"],
          metadata: claims["metadata"],
          ttl: ttl,
          grants: grants
        }

        {:ok, token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Creates an AccessToken struct from a JWT token string with verification.

  ## Parameters

  - `jwt`: The JWT token string to decode
  - `api_key`: The API key to verify against
  - `api_secret`: The API secret to verify with

  ## Returns

  - `{:ok, %AccessToken{}}`: If the token is valid, returns the AccessToken struct
  - `{:error, reason}`: If the token is invalid

  ## Examples

      iex> AccessToken.from_jwt(jwt_string, "api_key", "api_secret")
      {:ok, %AccessToken{identity: "user123", ...}}

  """
  @spec from_jwt(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, any()}
  def from_jwt(jwt, api_key, api_secret)
      when is_binary(jwt) and is_binary(api_key) and is_binary(api_secret) do
    case verify(jwt, api_key, api_secret) do
      {:ok, claims} ->
        # Calculate TTL from exp claim
        current_time = System.system_time(:second)
        exp_time = claims["exp"]
        ttl = if exp_time, do: max(0, exp_time - current_time), else: nil

        # Convert video grants from camelCase to snake_case
        grants = parse_video_grants(claims["video"])

        token = %__MODULE__{
          api_key: api_key,
          api_secret: api_secret,
          identity: claims["sub"],
          name: claims["name"],
          metadata: claims["metadata"],
          ttl: ttl,
          grants: grants
        }

        {:ok, token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Verifies a JWT token and returns its claims.

  ## Parameters

  - `token`: The JWT token to verify
  - `api_key`: The API key to verify against
  - `api_secret`: The API secret to verify with

  ## Returns

  - `{:ok, claims}`: If the token is valid, returns the decoded claims
  - `{:error, reason}`: If the token is invalid
  """
  @spec verify(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def verify(token, api_key, api_secret)
      when is_binary(token) and is_binary(api_key) and is_binary(api_secret) do
    signer = Joken.Signer.create("HS256", api_secret)

    case Joken.verify(token, signer) do
      {:ok, claims} ->
        # Verify that the issuer matches the API key
        if claims["iss"] == api_key do
          {:ok, claims}
        else
          {:error, :invalid_issuer}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private function to parse video grants from JWT claims
  defp parse_video_grants(nil), do: %Grants{}

  defp parse_video_grants(video_claims) when is_map(video_claims) do
    %Grants{
      room: video_claims["room"],
      room_join: video_claims["roomJoin"] || false,
      room_list: video_claims["roomList"] || false,
      room_record: video_claims["roomRecord"] || false,
      room_admin: video_claims["roomAdmin"] || false,
      room_create: video_claims["roomCreate"] || false,
      ingress_admin: video_claims["ingressAdmin"] || false
    }
  end

  defp parse_video_grants(_), do: %Grants{}
end
