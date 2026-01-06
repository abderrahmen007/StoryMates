//
//  zego 崩溃卡顿收集
//
//  zego_crash_monitor.hpp
//
//
//  Created by nikoli on 2023/05/22.
//

#ifndef zego_crash_monitor_hpp
#define zego_crash_monitor_hpp

#include "zego_crash_monitor_define.hpp"
#include <memory>
#include <vector>

namespace ZEGO {

namespace CRASH_MONITOR {
class CrashMonitorMgr;
class ZEGOCRASHMONITOR_API ZegoCrashMonitor {
  public:
    static std::shared_ptr<ZegoCrashMonitor> GetInstance();
    virtual ~ZegoCrashMonitor();

  private:
    ZegoCrashMonitor();

  public:
    /**
        初始化模块
        @param 初始化参数
     */
    void Init(const CrashMonitorParam& param);

    /**
        反初始化模块
    */
    void UnInit();

    /**
     *  开始会话
    */
    void StartSession();

    /**
     *  结束会话
    */
    void EndSession();


    /**
     *  设置自定义 tag 分类条件（可根据 tag 做数据占比百分比分析），非重要过滤性信息不要设置，会影响查询性能 （可用于查询条件）
     * @note 需要在 Init 之后调用，立即生效
    */
    void SetCustomTag(const std::string& tag, const std::string& value);

    /**
     *  设置自定义扩展信息 (不能用于查询记录条件)
     * @note 需要在 Init 之后调用，立即生效
    */
    void SetExtraInfo(const std::string& key, const std::string& value);

    /**
     *  设置用户 id， 可用于查询
     * @note 需要在 Init 之后调用，立即生效
    */
    void SetUserID(const std::string& id);

    /** 
     *  外部主动获取所有线程堆栈快照
     * @param name 提示名，可在后台标题中显示
     * @param reason 提示原因，可在后台标题中显示
     * @note 需要在 Init 之后调用，立即生效
     * @note 慎用，过程中会挂起线程
     * @note 在sentry 后台展示中，相同name 与 reason 的会被归纳为同一事件
    */
    void TakeStackSnapShot(const std::string& name, const std::string& reason);

    /**
       * @brief 添加要监控的线程
       * 
       * @param tid 要监控的线程 ID，iOS/macOS 平台需传入调用 pthread_self 函数获取到的值；Android/Linux 等平台需传入调用 gettid 函数获取到的值；Windows 平台需传入调用 GetCurrentThreadId 函数获取到的值。
       * @param threadName win 下无法线程名字，如果不设置，线程名默认以 thread id 展示。其他平台可忽略
       * @note 目前仅支持监控一个线程，后续支持多个线程
       * @note 在sentry 后台展示中，卡顿线程堆栈一致的会被归纳为同一事件
       * @note 在 Init 后调用
     */
    void AddMonitorThreadId(uint64_t tid, const std::string& threadName);

    /**
      * @brief 移除要监控的线程
      * 
      * @param tid 要移除监控的线程 ID，iOS/macOS 平台需传入调用 pthread_self 函数获取到的值；Android/Linux 等平台需传入调用 gettid 函数获取到的值；Windows 平台需传入调用 GetCurrentThreadId 函数获取到的值。
      * @note 在 Init 后调用
    */
    void RemoveMonitorThreadId(uint64_t tid);

    /**
        获取崩溃卡顿记录
        @param event_ids，可根据 id 集合获取记录集合，如果是空集合，则视为获取全部记录
        @param callback 获取的记录信息集合回调
        @note 可在每次初始化后，获取一次记录，拿到上次 sdk 崩溃卡顿的记录进行处理
        @note 在 Init 后调用
    */
    void GetRecordInfo(const std::vector<std::string> &event_ids, const OnGetRecordInfoCallback& callback);

    /**
        清除崩溃卡顿记录
        @param event_ids，可根据 id 集合清除记录集合，(如果是空集合，则视为清除全部记录 !!!暂不支持)
        @note 可在处理完每一条记录后，调用进行清除，那么本地数据就会清除掉
        @note 在 Init 后调用
    */
    void ClearRecordCache(const std::vector<std::string> &event_ids);


    /**
     *  设置附件路径
        @param event_id，可通过 [GetRecordInfo] 获取，或着在卡顿通知回调 [OnThreadMonitorBlockedNotify] 获取
        @param path 附件本地路径，需要可访问
        @param auto_delete_after_send 上传完后是否自动删除
        @note SetAttachment 用意是在尽量保持现场，业务层可收集当时的日志信息或其他信息。所以这里有两个时机可设置。
        @note 当发生线程卡顿时，[OnThreadMonitorBlockedNotify] 回调通知，可以在回调里处理，例如收集现场日志。
        @note 当发生崩溃时，可以在下次程序启动，[GetRecordInfo] 获取崩溃的时间戳，从而收集当时的日志。
    */
    void SetAttachment(const std::string& event_id, const std::string& path, bool auto_delete_after_send);

    /**
        发送所有记录到后台
        @note 在 Init 后调用
    */
    void SendAllRecords();

    /**
        取消发送
        @note 在 SendAllRecords 后调用
    */
    void CancelSend();

    /**
        更新上传速度，eg: 200kb = 200 * 1024
        @note 在 Init 后调用, 实时生效
    */
    void UpdateSendSpeed(int speed);

    /**
        设置线程卡顿监控协助处理
        @param delegate，sdk 线程卡顿回调协助处理
        @note 当进行线程卡顿监控时，sdk 回按照 Init 时设置的检查频率回调，开发者需要切换到对应的线程后，再执行 delegate 中的 func
              以便更精准监控卡顿的情况。
    */
    void SetThreadMonitorHandlerDelegate(const OnThreadMonitorHandlerDelegate &delegate);

    /**
        sdk 日志代理回调
        @param level，设置指定日志打印的级别
        @param delegate，sdk 的日志回调，可直接打印
        @note 当收到回调的时候，直接打印日志，方便追查问题
    */
    void SetLogDelegate(CrashMonitorLogLevel level, const OnCrashMonitorLogDelegate &delegate);

    /**
        sdk 错误回调
        @param delegate，sdk 的错误回调
    */
    void SetErrorDelegate(const OnCrashMonitorErrorDelegate &delegate);

    /**
        线程卡顿 通知回调
        @param notify 线程卡顿 通知回调
    */
    void SetThreadBlockedNotify(const OnThreadMonitorBlockedNotify &notify);

    /**
        堆栈快照 通知回调
        @param notify 堆栈快照 通知回调
    */
    void SetTakeStackSnapShotNotify(const OnTakeStackSnapShotNotify &notify);

    /**
        crash 通知回调
        @param notify crash 通知回调
    */
    void SetCrashNotify(const OnCrashNotify &notify);

    /**
        crash上报完成 通知回调
        @param notify crash上报完成 通知回调
    */
    void SetCrashUploadCompleteNotify(const OnCrashUploadCompleteNotify &notify);
  private:
    std::shared_ptr<CrashMonitorMgr> crash_mgr_ = nullptr;
};

} // namespace CRASH_MONITOR
} // namespace ZEGO

#endif /* zego_crash_monitor_hpp */
