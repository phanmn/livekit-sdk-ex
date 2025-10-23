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

# Add to your mix.exs dependencies:
# {:ex_constructor, "~> 1.2"}
# {:jason, "~> 1.4"}

# ============================================================================
# ENUMS
# ============================================================================

defmodule LivekitSdkEx.EncodedFileType do
  @moduledoc """
  File type for encoded file output.
  """

  @type t :: :default_filetype | :mp4 | :ogg | :mp3

  @default_filetype 0
  @mp4 1
  @ogg 2
  @mp3 3

  def default_filetype, do: @default_filetype
  def mp4, do: @mp4
  def ogg, do: @ogg
  def mp3, do: @mp3
end

defmodule LivekitSdkEx.StreamProtocol do
  @moduledoc """
  Protocol for stream output.
  """

  @type t :: :default_protocol | :rtmp | :srt

  @default_protocol 0
  @rtmp 1
  @srt 2

  def default_protocol, do: @default_protocol
  def rtmp, do: @rtmp
  def srt, do: @srt
end

defmodule LivekitSdkEx.SegmentedFileProtocol do
  @moduledoc """
  Protocol for segmented file output.
  """

  @type t :: :default_segmented_file_protocol | :hls_protocol

  @default_segmented_file_protocol 0
  @hls_protocol 1

  def default_segmented_file_protocol, do: @default_segmented_file_protocol
  def hls_protocol, do: @hls_protocol
end

defmodule LivekitSdkEx.SegmentedFileSuffix do
  @moduledoc """
  Suffix type for segmented files.
  """

  @type t :: :index | :timestamp

  @index 0
  @timestamp 1

  def index, do: @index
  def timestamp, do: @timestamp
end

defmodule LivekitSdkEx.ImageFileSuffix do
  @moduledoc """
  Suffix type for image files.
  """

  @type t :: :image_suffix_index | :image_suffix_timestamp | :image_suffix_none_overwrite

  @image_suffix_index 0
  @image_suffix_timestamp 1
  @image_suffix_none_overwrite 2

  def image_suffix_index, do: @image_suffix_index
  def image_suffix_timestamp, do: @image_suffix_timestamp
  def image_suffix_none_overwrite, do: @image_suffix_none_overwrite
end

defmodule LivekitSdkEx.ImageCodec do
  @moduledoc """
  Image codec type.
  """

  @type t :: :ic_default | :ic_jpeg

  @ic_default 0
  @ic_jpeg 1

  def ic_default, do: @ic_default
  def ic_jpeg, do: @ic_jpeg
end

defmodule LivekitSdkEx.AudioMixing do
  @moduledoc """
  Audio mixing mode.
  """

  @type t :: :default_mixing | :dual_channel_agent | :dual_channel_alternate

  @default_mixing 0
  @dual_channel_agent 1
  @dual_channel_alternate 2

  def default_mixing, do: @default_mixing
  def dual_channel_agent, do: @dual_channel_agent
  def dual_channel_alternate, do: @dual_channel_alternate
end

# ============================================================================
# STRUCTS
# ============================================================================

defmodule LivekitSdkEx.FilterParams do
  @derive Jason.Encoder
  defstruct [
    :include_events,
    :exclude_events
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          include_events: [String.t()] | nil,
          exclude_events: [String.t()] | nil
        }
end

defmodule LivekitSdkEx.WebhookConfig do
  @derive Jason.Encoder
  defstruct [
    :url,
    :signing_key,
    :filter_params
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          url: String.t() | nil,
          signing_key: String.t() | nil,
          filter_params: LivekitSdkEx.FilterParams.t() | nil
        }

  def new(map) do
    struct = super(map)

    %{struct | filter_params: maybe_new(LivekitSdkEx.FilterParams, struct.filter_params)}
  end

  defp maybe_new(_module, nil), do: nil
  defp maybe_new(module, value) when is_map(value), do: module.new(value)
  defp maybe_new(_module, value), do: value
end

defmodule LivekitSdkEx.EncodedFileOutput do
  @derive Jason.Encoder
  defstruct [
    :file_type,
    :filepath,
    :disable_manifest
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          file_type: LivekitSdkEx.EncodedFileType.t() | nil,
          filepath: String.t() | nil,
          disable_manifest: boolean() | nil
        }
end

defmodule LivekitSdkEx.StreamOutput do
  @derive Jason.Encoder
  defstruct [
    :protocol,
    :urls
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          protocol: LivekitSdkEx.StreamProtocol.t() | nil,
          urls: [String.t()] | nil
        }
end

defmodule LivekitSdkEx.SegmentedFileOutput do
  @derive Jason.Encoder
  defstruct [
    :protocol,
    :filename_prefix,
    :playlist_name,
    :live_playlist_name,
    :segment_duration,
    :filename_suffix,
    :disable_manifest
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          protocol: LivekitSdkEx.SegmentedFileProtocol.t() | nil,
          filename_prefix: String.t() | nil,
          playlist_name: String.t() | nil,
          live_playlist_name: String.t() | nil,
          segment_duration: non_neg_integer() | nil,
          filename_suffix: LivekitSdkEx.SegmentedFileSuffix.t() | nil,
          disable_manifest: boolean() | nil
        }
end

defmodule LivekitSdkEx.ImageOutput do
  @derive Jason.Encoder
  defstruct [
    :capture_interval,
    :width,
    :height,
    :filename_prefix,
    :filename_suffix,
    :image_codec,
    :disable_manifest
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          capture_interval: non_neg_integer() | nil,
          width: integer() | nil,
          height: integer() | nil,
          filename_prefix: String.t() | nil,
          filename_suffix: LivekitSdkEx.ImageFileSuffix.t() | nil,
          image_codec: LivekitSdkEx.ImageCodec.t() | nil,
          disable_manifest: boolean() | nil
        }
end

defmodule LivekitSdkEx.AutoTrackEgress do
  @derive Jason.Encoder
  defstruct [
    :filepath,
    :disable_manifest
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          filepath: String.t() | nil,
          disable_manifest: boolean() | nil
        }
end

defmodule LivekitSdkEx.AutoParticipantEgress do
  @derive Jason.Encoder
  defstruct [
    :file_outputs,
    :segment_outputs
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          file_outputs: [LivekitSdkEx.EncodedFileOutput.t()] | nil,
          segment_outputs: [LivekitSdkEx.SegmentedFileOutput.t()] | nil
        }

  def new(map) do
    struct = super(map)

    %{
      struct
      | file_outputs: maybe_new_list(LivekitSdkEx.EncodedFileOutput, struct.file_outputs),
        segment_outputs: maybe_new_list(LivekitSdkEx.SegmentedFileOutput, struct.segment_outputs)
    }
  end

  defp maybe_new_list(_module, nil), do: nil
  defp maybe_new_list(module, list) when is_list(list), do: Enum.map(list, &module.new/1)
  defp maybe_new_list(_module, value), do: value
end

defmodule LivekitSdkEx.RoomCompositeEgressRequest do
  @derive Jason.Encoder
  defstruct [
    :room_name,
    :layout,
    :audio_only,
    :audio_mixing,
    :video_only,
    :custom_base_url,
    :file_outputs,
    :stream_outputs,
    :segment_outputs,
    :image_outputs,
    :webhooks
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          room_name: String.t() | nil,
          layout: String.t() | nil,
          audio_only: boolean() | nil,
          audio_mixing: LivekitSdkEx.AudioMixing.t() | nil,
          video_only: boolean() | nil,
          custom_base_url: String.t() | nil,
          file_outputs: [LivekitSdkEx.EncodedFileOutput.t()] | nil,
          stream_outputs: [LivekitSdkEx.StreamOutput.t()] | nil,
          segment_outputs: [LivekitSdkEx.SegmentedFileOutput.t()] | nil,
          image_outputs: [LivekitSdkEx.ImageOutput.t()] | nil,
          webhooks: [LivekitSdkEx.WebhookConfig.t()] | nil
        }

  def new(map) do
    struct = super(map)

    %{
      struct
      | file_outputs: maybe_new_list(LivekitSdkEx.EncodedFileOutput, struct.file_outputs),
        stream_outputs: maybe_new_list(LivekitSdkEx.StreamOutput, struct.stream_outputs),
        segment_outputs: maybe_new_list(LivekitSdkEx.SegmentedFileOutput, struct.segment_outputs),
        image_outputs: maybe_new_list(LivekitSdkEx.ImageOutput, struct.image_outputs),
        webhooks: maybe_new_list(LivekitSdkEx.WebhookConfig, struct.webhooks)
    }
  end

  defp maybe_new_list(_module, nil), do: nil
  defp maybe_new_list(module, list) when is_list(list), do: Enum.map(list, &module.new/1)
  defp maybe_new_list(_module, value), do: value
end

defmodule LivekitSdkEx.RoomEgress do
  @derive Jason.Encoder
  defstruct [
    :room,
    :participant,
    :tracks
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          room: LivekitSdkEx.RoomCompositeEgressRequest.t() | nil,
          participant: LivekitSdkEx.AutoParticipantEgress.t() | nil,
          tracks: LivekitSdkEx.AutoTrackEgress.t() | nil
        }

  def new(map) do
    struct = super(map)

    %{
      struct
      | room: maybe_new(LivekitSdkEx.RoomCompositeEgressRequest, struct.room),
        participant: maybe_new(LivekitSdkEx.AutoParticipantEgress, struct.participant),
        tracks: maybe_new(LivekitSdkEx.AutoTrackEgress, struct.tracks)
    }
  end

  defp maybe_new(_module, nil), do: nil
  defp maybe_new(module, value) when is_map(value), do: module.new(value)
  defp maybe_new(_module, value), do: value
end

defmodule LivekitSdkEx.RoomAgentDispatch do
  @derive Jason.Encoder
  defstruct [
    :agent_name,
    :metadata
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          agent_name: String.t() | nil,
          metadata: String.t() | nil
        }
end

defmodule LivekitSdkEx.RoomConfiguration do
  @derive Jason.Encoder
  defstruct [
    :name,
    :empty_timeout,
    :departure_timeout,
    :max_participants,
    :metadata,
    :egress,
    :min_playout_delay,
    :max_playout_delay,
    :sync_streams,
    :agents
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          name: String.t() | nil,
          empty_timeout: non_neg_integer() | nil,
          departure_timeout: non_neg_integer() | nil,
          max_participants: non_neg_integer() | nil,
          metadata: String.t() | nil,
          egress: LivekitSdkEx.RoomEgress.t() | nil,
          min_playout_delay: non_neg_integer() | nil,
          max_playout_delay: non_neg_integer() | nil,
          sync_streams: boolean() | nil,
          agents: [LivekitSdkEx.RoomAgentDispatch.t()] | nil
        }

  def new(map) do
    struct = super(map)

    %{
      struct
      | egress: maybe_new(LivekitSdkEx.RoomEgress, struct.egress),
        agents: maybe_new_list(LivekitSdkEx.RoomAgentDispatch, struct.agents)
    }
  end

  defp maybe_new(_module, nil), do: nil
  defp maybe_new(module, value) when is_map(value), do: module.new(value)
  defp maybe_new(_module, value), do: value

  defp maybe_new_list(_module, nil), do: nil
  defp maybe_new_list(module, list) when is_list(list), do: Enum.map(list, &module.new/1)
  defp maybe_new_list(_module, value), do: value
end

defmodule LivekitSdkEx.VideoGrant do
  @derive Jason.Encoder
  defstruct [
    :room_create,
    :room_list,
    :room_record,
    :room_admin,
    :room_join,
    :room,
    :can_publish,
    :can_subscribe,
    :can_publish_data,
    :can_publish_sources,
    :can_update_own_metadata,
    :ingress_admin,
    :hidden,
    :recorder,
    :agent,
    :can_subscribe_metrics,
    :destination_room
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          room_create: boolean() | nil,
          room_list: boolean() | nil,
          room_record: boolean() | nil,
          room_admin: boolean() | nil,
          room_join: boolean() | nil,
          room: String.t() | nil,
          can_publish: boolean() | nil,
          can_subscribe: boolean() | nil,
          can_publish_data: boolean() | nil,
          can_publish_sources: [String.t()] | nil,
          can_update_own_metadata: boolean() | nil,
          ingress_admin: boolean() | nil,
          hidden: boolean() | nil,
          recorder: boolean() | nil,
          agent: boolean() | nil,
          can_subscribe_metrics: boolean() | nil,
          destination_room: String.t() | nil
        }
end

defmodule LivekitSdkEx.SIPGrant do
  @derive Jason.Encoder
  defstruct [
    :admin,
    :call
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          admin: boolean() | nil,
          call: boolean() | nil
        }
end

defmodule LivekitSdkEx.AgentGrant do
  @derive Jason.Encoder
  defstruct [
    :admin
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          admin: boolean() | nil
        }
end

defmodule LivekitSdkEx.InferenceGrant do
  @derive Jason.Encoder
  defstruct [
    :perform
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          perform: boolean() | nil
        }
end

defmodule LivekitSdkEx.ObservabilityGrant do
  @derive Jason.Encoder
  defstruct [
    :write
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          write: boolean() | nil
        }
end

defmodule LivekitSdkEx.ClaimGrants do
  @derive Jason.Encoder
  defstruct [
    :identity,
    :name,
    :kind,
    :video,
    :sip,
    :agent,
    :inference,
    :observability,
    :room_config,
    :room_preset,
    :sha256,
    :metadata,
    :attributes
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          identity: String.t() | nil,
          name: String.t() | nil,
          kind: String.t() | nil,
          video: LivekitSdkEx.VideoGrant.t() | nil,
          sip: LivekitSdkEx.SIPGrant.t() | nil,
          agent: LivekitSdkEx.AgentGrant.t() | nil,
          inference: LivekitSdkEx.InferenceGrant.t() | nil,
          observability: LivekitSdkEx.ObservabilityGrant.t() | nil,
          room_config: LivekitSdkEx.RoomConfiguration.t() | nil,
          room_preset: String.t() | nil,
          sha256: String.t() | nil,
          metadata: String.t() | nil,
          attributes: %{String.t() => String.t()} | nil
        }

  def new(map) do
    struct = super(map)

    %{
      struct
      | video: maybe_new(LivekitSdkEx.VideoGrant, struct.video),
        sip: maybe_new(LivekitSdkEx.SIPGrant, struct.sip),
        agent: maybe_new(LivekitSdkEx.AgentGrant, struct.agent),
        inference: maybe_new(LivekitSdkEx.InferenceGrant, struct.inference),
        observability: maybe_new(LivekitSdkEx.ObservabilityGrant, struct.observability),
        room_config: maybe_new(LivekitSdkEx.RoomConfiguration, struct.room_config)
    }
  end

  defp maybe_new(_module, nil), do: nil
  defp maybe_new(module, value) when is_map(value), do: module.new(value)
  defp maybe_new(_module, value), do: value
end
