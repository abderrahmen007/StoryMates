#pragma once

#include <stdint.h>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>


namespace zreporter
{
using ZBSeq = uint32_t;

struct zreporterOptions {
    /* 固定参数 业务相关 */ 
    uint32_t    appid;
    std::string appsignature;  /* 若不使用sign方式鉴权 调用SetToken接口设置或更新token */ 
    std::string deviceID;
    uint32_t    importantLevel = 0;  /* 默认[0,0]为重要Level (如计费相关) */ 
    std::string dbPath;              /* db路径 reporter 内部将在此路径下生成若干文件或文件夹用于本地存储 */ 

    /* 固定参数 通常使用默认值 */ 

    uint32_t memMaxSizeMB         = 10;    /* 内存超限将会按优先级落盘数据 */ 
    uint32_t dbMaxSizeMB          = 100;   /* DB超限将会按优先级删除数据 */ 

    std::string url;
};
using LogCallback_t = std::function<void(int level, const std::string& module, int line, const std::string& log)>;
using AcquireTokenbucketsCallback_t = std::function<bool(int data_size, unsigned int& limit)>;

////////////////////////////////错误码//////////////////////////////////////////

}  // namespace zreporter
