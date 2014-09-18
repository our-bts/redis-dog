cluster = require("cluster")
#logger = require("./common/logger")
numCPUs = require("os").cpus().length
if cluster.isMaster
  
  # Fork workers.
  i = 0

  while i < numCPUs
    cluster.fork()
    i++

  cluster.on "exit", (worker, code, signal) ->
    #不要使用子进程的logger，子进程退出可能是因为logger写入失败，这里如果主进程再写logger，会导致主进程也异常退出
    #console输出可以在service info文件查看
    console.error "worker #{worker.process.pid} died"
    cluster.fork()

else
    require "./index"