function job() {
  console.log('Running job')
}

function runJobs() {
  job()
  setTimeout(runJobs, 10000)
}

runJobs()
