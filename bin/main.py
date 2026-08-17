#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import logging
import shutil
import sys
from pathlib import Path
from subprocess import CompletedProcess, run
from typing import List, Optional

# Настройка логгера один раз на уровне модуля
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

class AssayoError(Exception):
  pass

def setup_paths(source_rel: str = '../assayo', dist_name: str = 'assayo') -> tuple[Path, Path]:
  source_path = Path(__file__).resolve().parent / source_rel
  if not source_path.exists():
    raise AssayoError(f"Source directory not found: {source_path}")
    
  dist_path = Path.cwd() / dist_name
  
  # Идемпотентность: всегда начинаем с чистого листа
  if dist_path.exists():
    logger.debug(f"Cleaning existing directory: {dist_path}")
    try:
      shutil.rmtree(dist_path)
    except PermissionError as e:
      raise AssayoError(f"Cannot remove old report dir. Is it open in another program? {e}")
      
  return source_path, dist_path

def copy_template(source: Path, destination: Path) -> None:
  try:
    shutil.copytree(source, destination)
    logger.info("HTML report template created.")
  except Exception as e:
    raise AssayoError(f"Failed to copy template: {e}")

def build_git_command(log_file: Path, use_raw: bool, no_file: bool) -> List[str]:
  cmd = ['git', '--no-pager', 'log']
  
  if use_raw and not no_file:
    cmd.extend(['--raw', '--numstat'])
    
  cmd.extend([
    '--oneline', '--all', '--reverse',
    '--date=iso-strict',
    '--pretty=format:%ad>%aN>%aE>%s'
  ])

  return cmd

def fetch_git_log(output_path: Path, command: List[str]) -> None:
  logger.info("Fetching git history...")
  try:
    with output_path.open('w', encoding='utf-8') as f:
      result: CompletedProcess = run(
        command, 
        capture_output=True, 
        text=True, 
        check=True,
        cwd=output_path.parent # Запускаем из папки репорта
      )
      f.write(result.stdout)
    logger.info(f"Git log saved to {output_path.name}.")
  except FileNotFoundError:
    raise AssayoError("'git' executable not found. Ensure Git is installed and added to PATH.")
  except run.CalledProcessError as e:
    stderr_msg = e.stderr.strip() or "Unknown error"
    raise AssayoError(f"Git command failed: {stderr_msg}")

def sanitize_content(text: str) -> str:
  return text.replace('`', '').replace('$', '')

def wrap_in_report_format(content: str) -> str:
  return f'R(f`{content}`);'

def process_log_file(file_path: Path) -> None:
  try:
    content = file_path.read_text(encoding='utf-8')
    cleaned = sanitize_content(content)
    wrapped = wrap_in_report_format(cleaned)
    file_path.write_text(wrapped, encoding='utf-8')
    logger.info("Log file sanitized and wrapped.")
  except UnicodeDecodeError:
    raise AssayoError(f"File {file_path} has non-utf8 encoding.")
  except Exception as e:
    raise AssayoError(f"Failed to process log file: {e}")

def main(argv: Optional[List[str]] = None) -> int:
  parser = argparse.ArgumentParser(description="Generate HTML report from git log.")
  parser.add_argument('--debug', action='store_true', help='Enable verbose debug output.')
  parser.add_argument('--no-file', action='store_true', help='Omit --raw and --numstat from git log.')
  
  args = parser.parse_args(argv)
  
  if args.debug:
    logger.setLevel(logging.DEBUG)

  try:
    src, dst = setup_paths()
    copy_template(src, dst)
    
    log_file = dst / 'log.txt'
    git_cmd = build_git_command(log_file, use_raw=True, no_file=args.no_file)
    
    fetch_git_log(log_file, git_cmd)
    process_log_file(log_file)
    
    logger.info("Assayo report generation completed successfully.")
    return 0

  except AssayoError as e:
    logger.error(e)
    return 1
  except KeyboardInterrupt:
    logger.warning("Operation cancelled by user.")
    return 2
  except Exception as e:
    logger.critical(f"Unexpected fatal error: {e}", exc_info=True)
    return 3

if __name__ == "__main__":
  sys.exit(main())