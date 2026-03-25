#!/usr/bin/env node

const fs = require('node:fs');
const { promisify, format } = require('node:util');
const { argv } = require('node:process');
const { exec } = require('node:child_process');
const path = require('node:path');

const asyncExec = promisify(exec);

const showMessage = argv.includes('--debug')
  ? (m) => console.log(`Assayo: ${m}`)
  : () => {};

function getErrorMessage(error) {
  if (typeof error !== "object" || error === null) {
    return String(error);
  }
  if (typeof error.stack === "string") {
    return error.stack;
  }
  return format("%o", error);
}

function onFatalError(error) {
  process.exitCode = 2;
  const message = getErrorMessage(error) || 'error';
  console.error(`Assayo: ${message}`);
}

function getSaveLogCommand(fileName) {
  const raw = argv.includes('--no-file') ? '' : '--raw --numstat';
  return `git --no-pager log ${raw} --oneline --all --reverse --date=iso-strict --pretty=format:"%ad>%aN>%aE>%s" > ${fileName}`;
}

(async function main() {
  process.on("uncaughtException", onFatalError);
  process.on("unhandledRejection", onFatalError);

  // folder, when library was saved
  const SOURCE_DIR = 'assayo';
  const SOURCE_PATH = __dirname;

  // folder, when user run library
  const DIST_DIR = 'assayo';
  const DIST_PATH = process.cwd();

  // 1. Copy folder ./assayo from package to ./assayo in project
  const source = path.resolve(SOURCE_PATH, SOURCE_DIR);
  const target = path.resolve(DIST_PATH, DIST_DIR);
  const copy = `cp -r ${source} ${target}`;
  await asyncExec(copy);
  showMessage('directory with HTML report was be created');

  // 2. Run "git log" and save output in file ./assayo/log.txt
  showMessage('reading git log was be started');
  const fileName =  path.resolve('./', DIST_DIR, 'log.txt');
  const command = getSaveLogCommand(fileName);
  await asyncExec(command);
  showMessage('the file with git log was be saved');

  // 3. Replace symbols in ./assayo/log.txt
  const content = fs.readFileSync(fileName, "utf8")
    .replace(/`/gim, '')
    .replace(/\$/gim, 'S');
  fs.writeFileSync(fileName, `R(f\`${content}\`);`);

}()).catch(onFatalError);
