# profile = "aws-cloud"
region = "us-west-1"

task_port                 = 80
task_env_vars             = {
    "env" : "dev"
}
# inline_policy_json_file   = ".json"
task_cpu                  = 256
task_memory               = 512
autoscaling_min_tasks     = 1
autoscaling_max_tasks     = 1
autoscaling_target_cpu    = 90.0 // %
autoscaling_target_memory = 90.0 // %