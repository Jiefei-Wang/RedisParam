## Exported object
## jobname, host, port, password, workerIdList, workerPidList
library(redux)
library(rdaemon)
library(futile.logger)
## Create the variables if not exist
if (!exists("api_client"))
    api_client <- hiredis(
        host = host,
        port = port,
        password = password)
if (!exists("workerIdList"))
    workerIdList <- c()
if (!exists("workerPidList"))
    workerPidList <- c()

## Remove the task if there is no worker
if (!exists("timer"))
        timer <- Sys.time()
if(length(workerPidList) == 0){
    if(difftime(Sys.time(), timer, units = "secs") > 60){
        killDaemon()
    }
}else{
    timer <- Sys.time()
}

## Remove the dead workers
processAlive <- sapply(workerPidList, isProcessAlive)
if (length(processAlive)) {
    workerIdList <- workerIdList[processAlive]
    workerPidList <- workerPidList[processAlive]
    killedWorkers <- length(processAlive) - length(workerPidList)
    if(killedWorkers){
        flog.info("%d workers are dead and removed from the daemon", killedWorkers)
    }
}

## Query the Redis server and
## find the task Ids carried by the current workers
workerTaskCaches <- sapply(workerIdList, RedisParam:::.workerTaskCacheName)
commands <- lapply(
    workerTaskCaches,
    function(x) redis$LRANGE(x, 0, 0)
)
taskIds <- api_client$pipeline(.commands = commands)

## Find the busy workers
busyWorkers <- sapply(taskIds, function(x) length(x) == 1)

if(length(busyWorkers)){
    busyWorkerTaskCaches <- workerTaskCaches[busyWorkers]
    busyTaskIds <- unlist(taskIds[busyWorkers])
    busyWorkerPid <- workerPidList[busyWorkers]
    taskCacheCmds <- lapply(
    busyWorkerTaskCaches,
    function(x) redis$LRANGE(x, 0, 0)
    )
    taskIdCmds <- lapply(
    busyTaskIds,
    function(x) redis$EXISTS(x)
    )
    cmds <- c(taskCacheCmds, taskIdCmds)
    ## Check the taskId again to make sure it is not changed
    response <- api_client$pipeline(.commands = cmds)

    ## Send SIGINT to the worker if its task is cancelled
    cmds <- list()
    for(i in seq_along(busyTaskIds)){
        workerPid <- busyWorkerPid[i]
        currentTaskId <- unlist(response[[i]])
        taskExists <- response[[i + length(busyTaskIds)]] == 1
        ## If the worker is still busy on the current task and
        ## The task has been cancelled
        if(identical(currentTaskId, unname(busyTaskIds[i])) && !taskExists){
            flog.info(
                "The worker's task has been cancelled, sending SIGINT to the worker %d",
                workerPid
            )
            rdaemon::interruptProcess(workerPid)
            cmds <- append(cmds, list(redis$DEL(busyWorkerTaskCaches[[i]])))
        }
    }
    if(length(cmds)){
        api_client$pipeline(.commands = cmds)
    }
}
