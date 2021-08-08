deamonPid <- new.env(parent = emptyenv())
## worker
registerDeamon <- function(constructor = NULL,
                           isInterrupted = NULL,
                           data = list()){
    pid <- Sys.getpid()
    deamonInputFile <- tempfile()
    deamonOutPutFile <- tempfile()

    ## Save the deamon data into a file
    deamonArgs <- list(workerPid = pid,
                       deamonOutPutFile = deamonOutPutFile,
                       constructor = constructor,
                       isInterrupted = isInterrupted,
                       data = data)
    save(deamonArgs, file = deamonInputFile)

    ## Run the deamon
    rscript <- R.home("bin/Rscript")
    script <- system.file(package="RedisParam", "script", "deamon_start.R")
    withr::with_envvar(
            list(BPDEAMON_INPUT_FILE = deamonInputFile),
            system2(rscript, shQuote(script), stdout = FALSE, wait = FALSE)
    )

}
deregisterDeamon <- function(){

}

## manager
interruptWorker <- function(x, id){}

## deamon
isInterrupted <- function(){}
