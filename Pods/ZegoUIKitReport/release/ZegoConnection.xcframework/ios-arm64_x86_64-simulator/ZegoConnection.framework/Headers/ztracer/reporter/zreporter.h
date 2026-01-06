#pragma once

/**
 *  see http://confluence.zego.cloud/pages/viewpage.action?pageId=12943408
 */

#include "zreporter-defs.h"

namespace zreporter
{
/**
 * 1. 同进程多产品接入时,每个产品一个Reporter对象
 * 2. 每个reporter各自配置策略 (触发、限速、优先级等)
 */
class IReporter
{
  public:
    static std::shared_ptr<IReporter> GetInstance(const std::string& product);

    /**
     * @brief    初始化模块
     *
     * @param    strAppID
     * @param    strAppSignature
     * @param    maxDBSize           DB最大大小(MB)
     * @attention     请确保ZegoConnectionHttp模块已经被初始化
     */
    virtual void Init(const zreporterOptions& options) = 0;
    virtual void UnInit(void)                          = 0;

    /**
     * @brief    设置公共字段
     *
     * @param    process
     */
    virtual void SetProcess(const std::string& process) = 0;

    /**
     * @brief    新的鉴权方式 token 接口
     *
     * @param    token
     */
    virtual void SetToken(const std::string& token) = 0;

    /**
     * @brief    上报的域名
     *
     * @param    url
     */
    virtual void SetUrl(const std::string& url) = 0;


    /**
     * @brief    最大堆积的数据,超过则触发上报
     * 
     * @param    packageSizeByte    最大堆积的数据@note     默认3000字节
     * @note     默认3000字节
     */
    virtual void SetPackageSizeByte(uint32_t  packageSizeByte) = 0;

    /**
     * @brief    最大堆积的事件数量,超过则触发上报
     * 
     * @param    packageItemCount  最大堆积的事件数量
     * @note     默认10条
     */
    virtual void SetPackageItemCount(uint32_t  packageItemCount) = 0;

    /**
     * @brief    定时上报时间间隔
     * 
     * @param    interval  定时上报时间间隔 ms
     * @note     大于0表示启用定时上报，默认不启动
     */
    virtual void SetReportInterval(uint32_t  interval) = 0;

    /**
     * @brief    上报重试时间间隔
     * 
     * @param    interval  上报重试时间间隔 ms
     * @note     默认15000ms
     */
    virtual void SetRetryInterval(uint32_t  interval) = 0;

    /**
    * @brief    等待NTP时间超时值
    *
    * @param    timeout    超时值 ms
    * @note     调用StartReport后，如果等待timeout后还未同步NTP时间(通过)，则进行上报，默认等待2000ms
    */
    virtual void SetWaitNtpTimeout(uint32_t timeout) = 0;

    /**
     * @brief    设置NTP时间差
     *
     * @param    time_offset    本地时间与NTP时间差值 ms
     */
    virtual void SetNtpOffset(int64_t timeOffset) = 0 ;

    /**
     * @brief    提交公共字段，并开始上报(某些跨层依赖字段 无法在初始化时确定，需要延迟获取，如id_name等)
     *
     * @param    user_name    用户名
     * @param    process    公共字段
     * {
          "appid":2587762184,
          "device_id":"df3c0cea-afff-44fe-ada7-6b4e50969000",
          "os_type":"WIN32",
          "product":"rtc_native",
          "report_version":33560064,
          "sdk_version":"2.22.0.1-feature-220829-201538-5a29742e06",
          "ve_version":"69c51810bb"
        }
     * @note     开始上报
     */
    virtual void StartReport(const std::string& userName, const std::string& process) = 0;

    /**
     * @brief    上报
     *
     * @param    content             data buffer (pbBuffer jsonStr or others)
     * @param    level               每条数据的优先级 影响内部的相关策略
     *                               1. 优先级0为最低优先级,随level增大 优先级越高
     *                               2. 上报数据时,优先级高的数据会优先上报
     *                               3. 计费相关优先级使用最大,其他优先级由业务方自定义即可
     * @param    instant             是否立即上报，不排队等待上报
     */
    virtual void Report(std::shared_ptr<std::string> name, std::shared_ptr<std::string> content, uint32_t level, bool instant) = 0;
    virtual void Report(std::string&& name, std::string&& content, uint32_t level, bool instant)                               = 0;
    virtual void Report(const std::string& name, const std::string& content, uint32_t level, bool instant)                     = 0;

    /**
     * @brief    立即上报
     *
     */
    virtual void InstantReport() = 0;
    /**
     * @brief    暂停/恢复 (Level0)
     *
     */
    virtual void Pause(void)  = 0;
    virtual void Resume(void) = 0;

  public:
    /**
     * @brief    设置回调
     */
    virtual void SetReporterLogCallback(const LogCallback_t& log_callback) = 0;
    virtual void SetAcquireTokenbucketsCallback(const AcquireTokenbucketsCallback_t& tokenbuckets_callback) = 0;
};

}  // namespace zreporter