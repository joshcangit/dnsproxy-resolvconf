#!/usr/bin/env python
from importlib import util as libutil
from os import linesep
from pathlib import Path
from subprocess import run
from sys import exit as sys_exit, argv

if len(argv) < 2: sys_exit()

libs = ["ruamel", "yaml"]
libs = [x for x in libs if libutil.find_spec(x)]
if len(libs) < 1:
  sys_exit("No PyYAML or ruamel.yaml installed.")

def ruamel_yaml(fp):
  from ruamel.yaml import YAML
  yaml=YAML(typ='safe')
  return yaml.load(fp)

def pyyaml(fp):
  try: from yaml import CSafeLoader as SafeLoader, load
  except ImportError:
    from yaml import SafeLoader, load
  finally: return load(fp, SafeLoader)

yaml_load = {
  "ruamel": ruamel_yaml,
  "yaml": pyyaml
}
yaml_file = Path("/etc/adguard/dnsproxy.yml")
listen_addrs = []

with open(yaml_file, 'r') as fp:
  yaml_object = yaml_load[libs[0]](fp)
  listen_addrs = yaml_object['listen-addrs']

conf = [f"nameserver {x}" for x in listen_addrs] + ["options edns0"]

resolv_file = Path("/etc/resolvconf/resolv.conf.d/head")
resolv = []

with open(resolv_file, 'r') as fp:
  resolv = fp.read().splitlines()

def resolv_conf(filepath, in_list, mode):
  with open(filepath, mode) as fp:
    fp.write(linesep.join(in_list))
  run(["resolvconf", "-u"])

def starter(command):
  new_conf = [x for x in conf if x not in resolv]
  if len(new_conf) > 0:
    resolv_conf(resolv_file, new_conf, 'a')
    run(command)

def stopper(command):
  new_conf = [x for x in resolv if x not in conf]
  if new_conf != resolv:
    run(command)
    if new_conf[-1]: new_conf[-1] += linesep
    resolv_conf(resolv_file, new_conf, 'w')

dispatch = {
  "start": starter,
  "stop": stopper
}

dnsproxy = Path(__file__).parent.absolute() / "dnsproxy"

process = {
  "start": [dnsproxy, f"--config-path={yaml_file}"],
  "stop": ["killall", "-9", dnsproxy]
}

arg = argv[1]
dispatch[arg](process[arg])
