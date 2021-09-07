loadDaemon <-
    function(jobname, workerId,
             host, port, password)
{
    ## start the daemon
    rdaemon::registerDaemon(
        daemonName = "RPDaemon"
    )

    ## Intialize the task
    taskId <- paste0(host, "-", port, "-", jobname)
    script <- system.file(
        package="RedisParam",
        "script",
        "daemonScript.R"
    )
    exports <- list(
        jobname = jobname,
        host = host,
        port = as.integer(port),
        password = password
    )
    rdaemon::daemonSetTaskScript(
        taskId = taskId,
        script = script,
        exports = exports
    )

    ## Create the list objects if not exist
    rdaemon::daemonEval(
        taskId = taskId,
        expr = {
            if(!exists("workerIdList"))
                workerIdList <- c()
            if(!exists("workerPidList"))
                workerPidList <- c()
        }
    )

    ## Add the worker task cache to workerIdList
    workerIdExpr <- paste0(
        "workerIdList <- append(workerIdList, ",
        dQuote(workerId, q = FALSE)
        ,")"
    )
    ## Add the worker pid to workerPidList
    pidExpr <- paste0(
        "workerPidList <- append(workerPidList, ",
        Sys.getpid()
        ,")"
    )
    ## Evaluate the expression in the daemon
    expr.char <- paste0(workerIdExpr, "\n", pidExpr)
    rdaemon::daemonEval(
        taskId = taskId,
        expr.char = expr.char
        )
}

unloadDaemon <- function(){
    rdaemon::deregisterDaemon(daemonName = "RPDaemon")
}

removeDaemon <- function(){
    rdaemon::killDaemon(daemonName = "RPDaemon")
}
