defmodule Utils.EFlameProfiler do
  @moduledoc """
  Shared module for EFlame profiling functionality.

  Provides conditional profiling based on the EFLAME_OUTPUT_DIR environment variable.
  When the environment variable is set, profiling is enabled and flame graph files
  are generated in the specified directory.
  """

  require Logger

  defp get_eflame_output_dir do
    case :persistent_term.get({__MODULE__, :eflame_output_dir}, :not_set) do
      :not_set ->
        dir = System.get_env("EFLAME_OUTPUT_DIR")
        Logger.info("EFLAME_OUTPUT_DIR = #{dir}")
        :persistent_term.put({__MODULE__, :eflame_output_dir}, dir)
        dir

      dir ->
        dir
    end
  end

  @doc """
  Conditionally profiles a function call using EFlame.

  If EFLAME_OUTPUT_DIR is set, the function is profiled and a flame graph is generated.
  Otherwise, the function is called directly without profiling.

  ## Parameters

  - `module`: The module containing the function to profile
  - `function`: The function name to profile
  - `args`: Arguments to pass to the function
  - `log_message`: Optional log message to include (defaults to generic message)

  ## Returns

  The result of the function call.
  """
  def profile_call(module, function, args) do
    eflame_output_dir = get_eflame_output_dir()

    if eflame_output_dir do
      start_time = System.monotonic_time(:nanosecond)
      
      timestamp_us = DateTime.utc_now() |> DateTime.to_unix(:microsecond)
      random_hex = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
      output_file = "#{eflame_output_dir}/#{module}.#{function}.#{timestamp_us}.#{random_hex}.stacks.out"

      message = "#{module}.#{function} - Starting flame graph profiling, output: #{output_file}"
      Logger.info(message)

      result = :eflame.apply(:normal, output_file, module, function, args)
      
      end_time = System.monotonic_time(:nanosecond)
      elapsed_time = end_time - start_time
      
      IO.puts(:stderr, "TIMING: #{module}.#{function} start=#{start_time}ns end=#{end_time}ns elapsed=#{elapsed_time}ns")
      
      result
    else
      apply(module, function, args)
    end
  end
end