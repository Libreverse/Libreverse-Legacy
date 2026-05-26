# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Only run in Rails server/console mode, not during rake tasks
return if defined?(Rake) || !defined?(Rails::Server) && !Rails.const_defined?(:Console)

# Helper to execute SET safely
def set_var(sql)
  ActiveRecord::Base.connection.execute(sql)
rescue StandardError => e
  Rails.logger.debug "Warning: Failed to apply '#{sql}': #{e.message}"
end

# Plan Caching (big wins for Rails)
set_var("SET GLOBAL tidb_enable_non_prepared_plan_cache = ON")
set_var("SET SESSION tidb_enable_non_prepared_plan_cache = ON")
set_var("SET GLOBAL tidb_enable_non_prepared_plan_cache_for_dml = ON")
set_var("SET SESSION tidb_enable_non_prepared_plan_cache_for_dml = ON")
set_var("SET GLOBAL tidb_enable_instance_plan_cache = ON") # GLOBAL only (v8.4+)
set_var("SET GLOBAL tidb_instance_plan_cache_max_size = 4294967296") # 4GB in bytes (adjust to your RAM)
set_var("SET GLOBAL tidb_ignore_prepared_cache_close_stmt = ON")
set_var("SET SESSION tidb_ignore_prepared_cache_close_stmt = ON")
set_var("SET GLOBAL tidb_non_prepared_plan_cache_size = 500000") # Increased from 100000 for high query diversity
set_var("SET SESSION tidb_non_prepared_plan_cache_size = 500000")
set_var("SET GLOBAL tidb_plan_cache_max_plan_size = 0") # Unlimited
set_var("SET SESSION tidb_plan_cache_max_plan_size = 0")
set_var("SET GLOBAL tidb_enable_plan_cache_for_subquery = ON")
set_var("SET SESSION tidb_enable_plan_cache_for_subquery = ON")
set_var("SET GLOBAL tidb_enable_plan_cache_for_param_limit = ON")
set_var("SET SESSION tidb_enable_plan_cache_for_param_limit = ON")
set_var("SET GLOBAL tidb_plan_cache_invalidation_on_fresh_stats = ON")
set_var("SET SESSION tidb_plan_cache_invalidation_on_fresh_stats = ON")

# Optimizer Boosters
set_var("SET GLOBAL tidb_opt_agg_push_down = ON")
set_var("SET SESSION tidb_opt_agg_push_down = ON")
set_var("SET SESSION tidb_opt_distinct_agg_push_down = ON") # SESSION only
set_var("SET GLOBAL tidb_opt_skew_distinct_agg = ON")
set_var("SET SESSION tidb_opt_skew_distinct_agg = ON")
set_var("SET GLOBAL tidb_opt_limit_push_down_threshold = 1000000")
set_var("SET SESSION tidb_opt_limit_push_down_threshold = 1000000")
set_var("SET GLOBAL tidb_opt_projection_push_down = ON")
set_var("SET SESSION tidb_opt_projection_push_down = ON")
set_var("SET GLOBAL tidb_opt_enable_hash_join = ON")
set_var("SET SESSION tidb_opt_enable_hash_join = ON")
set_var("SET GLOBAL tidb_opt_enable_late_materialization = ON")
set_var("SET SESSION tidb_opt_enable_late_materialization = ON")
set_var("SET GLOBAL tidb_opt_enable_mpp_shared_cte_execution = ON")
set_var("SET SESSION tidb_opt_enable_mpp_shared_cte_execution = ON")
set_var("SET GLOBAL tidb_opt_insubq_to_join_and_agg = ON")
set_var("SET SESSION tidb_opt_insubq_to_join_and_agg = ON")
set_var("SET GLOBAL tidb_opt_join_reorder_threshold = 0")
set_var("SET SESSION tidb_opt_join_reorder_threshold = 0")
set_var("SET GLOBAL tidb_enable_cascades_planner = ON")
set_var("SET SESSION tidb_enable_cascades_planner = ON")
set_var("SET GLOBAL tidb_cost_model_version = 2")
set_var("SET SESSION tidb_cost_model_version = 2")
set_var("SET GLOBAL tidb_optimizer_selectivity_level = 0")
set_var("SET SESSION tidb_optimizer_selectivity_level = 0")
set_var("SET GLOBAL tidb_opt_three_stage_distinct_agg = ON")
set_var("SET SESSION tidb_opt_three_stage_distinct_agg = ON")
set_var("SET GLOBAL tidb_allow_mpp = ON")                                       # For TiFlash integration
set_var("SET SESSION tidb_allow_mpp = ON")
set_var("SET SESSION tidb_enforce_mpp = ON")                                    # Session only, for forcing MPP
set_var("SET SESSION tidb_runtime_filter_mode = 'LOCAL'")                       # Session only

# Concurrency & Execution
set_var("SET GLOBAL tidb_max_chunk_size = 128")
set_var("SET SESSION tidb_max_chunk_size = 128")
set_var("SET GLOBAL tidb_distsql_scan_concurrency = 20")
set_var("SET SESSION tidb_distsql_scan_concurrency = 20")
set_var("SET GLOBAL tidb_executor_concurrency = 16")
set_var("SET SESSION tidb_executor_concurrency = 16")
set_var("SET GLOBAL tidb_index_join_batch_size = 32768")
set_var("SET SESSION tidb_index_join_batch_size = 32768")
set_var("SET GLOBAL tidb_index_lookup_concurrency = 8")
set_var("SET SESSION tidb_index_lookup_concurrency = 8")
set_var("SET GLOBAL tidb_index_serial_scan_concurrency = 8")
set_var("SET SESSION tidb_index_serial_scan_concurrency = 8")
set_var("SET GLOBAL tidb_hash_join_concurrency = 16")
set_var("SET SESSION tidb_hash_join_concurrency = 16")
set_var("SET GLOBAL tidb_projection_concurrency = 16")
set_var("SET SESSION tidb_projection_concurrency = 16")
set_var("SET GLOBAL tidb_window_concurrency = 16")
set_var("SET SESSION tidb_window_concurrency = 16")
set_var("SET GLOBAL tidb_enable_parallel_apply = ON")
set_var("SET SESSION tidb_enable_parallel_apply = ON")
set_var("SET GLOBAL tidb_enable_pipelined_window_function = ON")
set_var("SET SESSION tidb_enable_pipelined_window_function = ON")

# Statistics
set_var("SET GLOBAL tidb_analyze_column_options = 'ALL'") # GLOBAL only
set_var("SET GLOBAL tidb_stats_load_sync_wait = 5000")
set_var("SET SESSION tidb_stats_load_sync_wait = 5000")
set_var("SET GLOBAL tidb_enable_auto_analyze = ON")                             # GLOBAL only
set_var("SET GLOBAL tidb_auto_analyze_ratio = 0.3")                             # GLOBAL only
set_var("SET GLOBAL tidb_enable_historical_stats = ON")                         # GLOBAL only
set_var("SET GLOBAL tidb_enable_fast_analyze = ON")
set_var("SET SESSION tidb_enable_fast_analyze = ON")

# Transaction/Read Optimizations (if your app can tolerate relaxed consistency)
set_var("SET GLOBAL tidb_rc_read_check_ts = ON") # GLOBAL only
set_var("SET GLOBAL tidb_guarantee_linearizability = OFF")
set_var("SET SESSION tidb_guarantee_linearizability = OFF")
set_var("SET SESSION tidb_read_consistency = 'weak'")                           # SESSION only
set_var("SET SESSION tidb_read_staleness = -5")                                 # SESSION only, 5s staleness
set_var("SET SESSION tidb_replica_read = 'leader-and-follower'")                # SESSION only

# Memory Tweaks (monitor closely!)
set_var("SET GLOBAL tidb_mem_quota_query = 16106127360")                        # 16GB in bytes (e.g., 16 * 1024**3)
set_var("SET SESSION tidb_mem_quota_query = 16106127360")
set_var("SET GLOBAL tidb_server_memory_limit = '70%'")                          # 70% of system memory (or bytes)
