#!/usr/bin/env bash
# Ref: https://github.com/concourse/docker-image-resource/blob/master/assets/common.sh

LOG_FILE=${LOG_FILE:-/tmp/docker.log}
SKIP_PRIVILEGED=${SKIP_PRIVILEGED:-false}

sanitize_cgroups() {
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  mount -o remount,rw /sys/fs/cgroup

  sed -e 1d /proc/cgroups | while read sys hierarchy num enabled; do
    if [ "$enabled" != "1" ]; then
      # subsystem disabled; skip
      continue
    fi

    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<$sys\\>")" || true
    if [ -z "$grouping" ]; then
      # subsystem not mounted anywhere; mount it on its own
      grouping="$sys"
    fi

    mountpoint="/sys/fs/cgroup/$grouping"

    mkdir -p "$mountpoint"

    # clear out existing mount to make sure new one is read-write
    if mountpoint -q "$mountpoint"; then
      umount "$mountpoint"
    fi

    mount -n -t cgroup -o "$grouping" cgroup "$mountpoint"

    if [ "$grouping" != "$sys" ]; then
      if [ -L "/sys/fs/cgroup/$sys" ]; then
        rm "/sys/fs/cgroup/$sys"
      fi

      ln -s "$mountpoint" "/sys/fs/cgroup/$sys"
    fi
  done

  if ! test -e /sys/fs/cgroup/systemd ; then
    mkdir /sys/fs/cgroup/systemd
    mount -t cgroup -o none,name=systemd none /sys/fs/cgroup/systemd
  fi
}

start_docker() {
  mkdir -p /var/log
  mkdir -p /var/run

  if [ "$SKIP_PRIVILEGED" = "false" ]; then
    sanitize_cgroups

    # check for /proc/sys being mounted readonly, as systemd does
    if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
      mount -o remount,rw /proc/sys
    fi
  fi

  local mtu=$(cat /sys/class/net/$(ip route get 8.8.8.8|awk '{ print $5 }')/mtu)
  local server_args="--mtu ${mtu} -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"
  local registry=""


  server_args="${server_args} --max-concurrent-downloads=$1 --max-concurrent-uploads=$2"

  for registry in $3; do
    server_args="${server_args} --insecure-registry ${registry}"
  done

  if [ -n "$4" ]; then
    server_args="${server_args} --registry-mirror $4"
  fi

  export server_args LOG_FILE
  declare -fx try_start
  trap stop_docker EXIT


dockerd --data-root /scratch/docker ${server_args} >$LOG_FILE 2>&1 &
echo $! > /tmp/docker.pid

sleep 1

until docker info >/dev/null 2>&1; do
  sleep 1
  echo waiting for docker to come up...
done

}

stop_docker() {
  local pid=$(cat /tmp/docker.pid)
  if [ -z "$pid" ]; then
    return 0
  fi

  kill -TERM $pid
}