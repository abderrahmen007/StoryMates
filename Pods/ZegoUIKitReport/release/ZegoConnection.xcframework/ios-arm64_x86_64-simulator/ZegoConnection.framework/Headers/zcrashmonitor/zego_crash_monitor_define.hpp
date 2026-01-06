#ifndef zego_crash_monitor_define_hpp
#define zego_crash_monitor_define_hpp

#define ZEGOCRASHMONITOR_API // * nothing

#include <functional>
#include <string>
#include <vector>
#include <map>

namespace ZEGO {

namespace CRASH_MONITOR {

using ZCMSeq = unsigned int;
using ZCMError = unsigned int;

////////////////////////////////错误码//////////////////////////////////////////
const ZCMError kZCSuccess = 0; //执行成功

struct CrashMonitorParam {
    unsigned int appid = 0;                                            //appid 必填
    std::string db_path;                                               //缓存目录 必填
    std::string sdk_framework;                                         //指定捕捉特定库， 空的时候代表捕捉整个app
    std::string main_version;                                          //主版本号，eg.迭代版本号 3.9.0， 不带编译号 必填
    std::string build_version;                                         //完整的版本号，带编译号. eg.3.9.0.1234.
    std::string device_id;                                             //设备id
    std::string dsn_path;                                              //sentry 项目url 必填 
    std::string base_url;                                              //log report 地址 必填
    std::string productId;                                             //产品 id 必填
    unsigned int thread_check_interval = 1000;                         //线程卡顿轮询检测间隔
    unsigned int thread_block_timeout = 8000;                          //线程卡顿时长
    unsigned int upload_max_speed = 200 * 1024;                        //报告上报速率限制, 
    double crash_sample_rate = 1.0;                                    //崩溃采样率
    double block_sample_rate = 1.0;                                    //卡顿采样率
    double snapshot_sample_rate = 1.0;                                 //线程快照采样率
    double attachment_sample_rate = 0.0;                               //附件上报采样率
    bool catch_logcat = false;                                         //安卓下是否抓起logcat
    int android_api_level = 0;                                         //安卓 api 等级
    bool catch_minidump = true;                                         //win下是否抓minidmp
};

//崩溃类型
enum RecordType {
    UNKNOW = 0,                                                        //未知，初始值
    CRASH = 1,                                                         //崩溃
    BLOCK = 2,                                                         //卡顿
    TAKESNAPSHOT = 3,                                                  //线程快照
};

struct RecordInfo{
    std::string event_id;                                              //记录 id
    RecordType type = UNKNOW;                                          //记录类型
    uint64_t timestamp = 0;                                            //时间戳
    std::string attachment;                                            //附件路径 （压缩包后的路径）
    bool auto_delete_attachment = false;                               //上传完是否主动删除路径
    std::string extra_path;                                            //额外信息路径（eg.logcat）
};


enum CrashMonitorLogLevel {
    LOGDEBUG = 0,
    LOGINFO,
    LOGWARN,
    LOGERROR,
};

//sdk 日志回调
using OnCrashMonitorLogDelegate =
    std::function<void(const CrashMonitorLogLevel level, const std::string &msg)>;

//sdk 错误回调
using OnCrashMonitorErrorDelegate = std::function<void(ZCMError error, std::string &msg)>;

//sdk 线程监控协助回调
using OnThreadMonitorHandlerDelegate =
    std::function<void(uint64_t tid, std::function<void()> func)>;

//sdk 线程卡顿捕捉完成回调（可在回调里，做日志收集工作）
using OnThreadMonitorBlockedNotify = std::function<void(uint64_t thread_id, const std::string &event_id)>;

//sdk 获取线程快照完成回调（可在回调里，做日志收集工作）
using OnTakeStackSnapShotNotify = std::function<void(const std::string &name, const std::string &reason, const std::string &event_id)>;

//sdk 崩溃上传完成回调
using OnCrashNotify = std::function<void()>;

//sdk 崩溃上传完成回调
using OnCrashUploadCompleteNotify = std::function<void()>;

//sdk 获取获取崩溃卡顿记录回调
using OnGetRecordInfoCallback = std::function<void(const std::vector<RecordInfo> &record_infos)>;
} // namespace CRASH_MONITOR
} // namespace ZEGO

#endif /* zego_crash_monitor_define_hpp */
