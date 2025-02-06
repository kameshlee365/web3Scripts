#!/bin/bash

# 基础目录路径
BASE_DIR="$PWD"

# 定义kaleido、可执行文件名和目录名变量
KALEIDO_PREFIX="DiscordBot"
EXECUTABLE_NAME="dc_mac"  # 可执行文件名
INSTANCE_DIR_NAME="Discord_Mac"  # 目录名

# 启动指定实例的函数
start_instance() {
    local instance_num=$1
    local instance_dir="${INSTANCE_DIR_NAME}${instance_num}"
    local full_path_no_suffix="${BASE_DIR}/${instance_dir}/${EXECUTABLE_NAME}"
    local full_path_with_suffix="${full_path_no_suffix}.bin"
    
    if [ -f "$full_path_no_suffix" ]; then
        full_path="$full_path_no_suffix"
    elif [ -f "$full_path_with_suffix" ]; then
        full_path="$full_path_with_suffix"
    else
        echo "Error: Executable not found in ${instance_dir}"
        return
    fi

    if ! screen -ls | grep -q "${KALEIDO_PREFIX}${instance_num}"; then
        screen -dmS "${KALEIDO_PREFIX}${instance_num}" bash -c "$full_path; exec bash"
        echo "Started ${INSTANCE_DIR_NAME}${instance_num} in screen session ${KALEIDO_PREFIX}${instance_num}"
        echo "Running in directory: ${instance_dir}"
    else
        echo "Screen session ${KALEIDO_PREFIX}${instance_num} already exists"
    fi
}

# 启动所有实例的函数
start_all() {
    local num_instances=$1
    local template_dir="${BASE_DIR}/${INSTANCE_DIR_NAME}0"

    if [ ! -d "$template_dir" ]; then
        echo "Error: Template directory ${template_dir} does not exist"
        return 1
    fi

    for ((i=1; i<=num_instances; i++)); do
        local instance_dir="${BASE_DIR}/${INSTANCE_DIR_NAME}${i}"
        
        if [ ! -d "$instance_dir" ]; then
            cp -r "$template_dir" "$instance_dir"
            echo "Copied template to ${instance_dir}"
        fi

        start_instance $i
    done
}

# 关闭所有kaleido相关的screen会话
close_all() {
    # 检查是否有运行中的screen会话
    if ! screen -ls | grep -q "${KALEIDO_PREFIX}"; then
        echo "No ${KALEIDO_PREFIX} screen sessions found"
        return
    fi
    
    # 获取所有kaleido会话并关闭
    screen -ls | grep "${KALEIDO_PREFIX}" | cut -d. -f1 | while read pid; do
        screen -X -S $pid quit
        echo "Closed screen session with pid $pid"
    done
    echo "All ${KALEIDO_PREFIX} screen sessions have been closed"
}

# 使用方法说明
usage() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  <number>  - Start single instance (e.g., $0 39)"
    echo "  all      - Start all instances"
    echo "  close    - Close all Kaleido screen sessions"
}

# 主逻辑
case $1 in
    "all"|"All"|"ALL")
        if [[ -z $2 || ! $2 =~ ^[0-9]+$ ]]; then
            echo "Please specify the number of instances to start"
            exit 1
        fi
        start_all $2
        ;;
    "close"|"Close"|"CLOSE")
        close_all
        ;;
    ""|"help"|"-h"|"--help")
        usage
        ;;
    [0-9]*)
        start_instance $1
        ;;
    *)
        echo "Invalid command: $1"
        usage
        exit 1
        ;;
esac