const process = require("process")
const { spawn } = require("child_process")
const fs = require("fs")

// basic implementation of @action/core.getInput()
function getInput(name) {
  return process.env[`INPUT_${name.toUpperCase()}`].trim()
}

// collect action inputs:
let setupOpts = []
if (getInput("skip-login") === "true") setupOpts.push("--skip-login")
if (getInput("latest") === "true")     setupOpts.push("latest")

let buildOpts = [], value
if ((value = getInput("repository")) !== "")        buildOpts.push(`-r ${value}`)
if ((value = getInput("repository-suffix")) !== "") buildOpts.push(`-s ${value}`)
if ((value = getInput("tag-suffix")) !== "")        buildOpts.push(`-t ${value}`)
if ((value = getInput("build-directory")) !== "")   buildOpts.push(`-d ${value}`)
if ((value = getInput("build-options")) !== "")     buildOpts.push(`-o "${value}"`)

// generate a local build.sh script:
fs.writeFileSync("build.sh", `#! bash
source ${__dirname}/build.sh
dockerSetup ${setupOpts.join(" ")}
echo $VERSION > VERSION
dockerBuildAndPush ${buildOpts.join(" ")}
`)

// execute it:
const build = spawn("bash", ["build.sh"], { maxBuffer: 100 * 1024 * 1024 })
build.stdout.on("data", data => { process.stdout.write(data) })
build.stderr.on("data", data => { process.stderr.write(data) })
build.on("error", error => { console.error(error) })
build.on("exit", code => { process.exit(code) })
