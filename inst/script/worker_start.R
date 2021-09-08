host <- Sys.getenv("REDISPARAM_HOST")
password <- Sys.getenv("REDISPARAM_PASSWORD")
port <- as.integer(Sys.getenv("REDISPARAM_PORT"))
jobname <- Sys.getenv("REDISPARAM_JOBNAME")
id <- Sys.getenv("REDISPARAM_ID")
daemon <- Sys.getenv("REDISPARAM_DAEMON")
daemon <- daemon == "TRUE"

param <- RedisParam::RedisParam(
    jobname = jobname,
    redis.hostname = host,
    redis.port = port,
    redis.password = password,
    is.worker = TRUE,
    daemon = daemon
)

RedisParam::bpstart(param)
