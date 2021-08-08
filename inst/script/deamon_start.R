## Read the deamon argument
deamonInputFile <- Sys.getenv("BPDEAMON_INPUT_FILE")
deamonArgs <- load(deamonInputFile)

workerPid <- deamonArgs$workerPid
deamonOutPutFile <- deamonArgs$deamonOutPutFile
constructor <- deamonArgs$constructor
isInterrupted <- deamonArgs$isInterrupted
data <- deamonArgs$data

stopifnot(!is.null(constructor)||!is.null(isInterrupted))

isProcessAlive <- function(pid){
    tryCatch(
        if(Sys.info()[['sysname']]=="Windows"){
            out = system2("wmic",
                          paste0('process where "ProcessID = ',pid, '" get processid'),
                          stdout = TRUE)
            any(grepl(pid, out, fixed = TRUE))
        }else{
            system2("ps", c("-p", pid), stdout = NULL, stderr = NULL) == 0L
        },
        warning = function(e) TRUE,
        error = function(e) TRUE
    )
}

i = 0

checkWorkerInterrupt <- function(){
    if(!is.null(isInterrupted) && !isProcessAlive(workerPid)){
        constructor(data)
    }
}

checkInterval <- 60
lastCheckTime <- Sys.time()
waitingTime <- 999
repeat {
    tryCatch({
        if(!is.null(constructor) && !isProcessAlive(workerPid)){
            constructor(data)
        }
        if(!is.null(isInterrupted)){
            if(isInterrupted(data)){

            }
        }

        ## wait for a minute
        currentTime <- Sys.time()
        waitingTime <- difftime(currentTime, lastCheckTime, units = "secs")
        if(waitingTime < checkInterval){
            Sys.sleep(checkInterval - waitingTime)
        }
        lastCheckTime <- Sys.time()
    },
    warning = function(e) NULL,
    error = function(e) NULL,
    interrupt = function(e) NULL
    )
}
