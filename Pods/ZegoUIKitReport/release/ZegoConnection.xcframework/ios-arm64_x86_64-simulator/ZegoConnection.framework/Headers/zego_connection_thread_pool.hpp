#ifndef zego_connection_thread_pool_hpp
#define zego_connection_thread_pool_hpp

#include <memory>
#include <zegotask.h>
#include "zego_connection_thread_pool_define.hpp"

/*
  ThreadPool 内部功能分为2部分: 
  1、threadpool 中会外部需要调用CreateTask 中来获取线程 用户需要使用ReleaseTask来归还线程给线程池
  2、defaulthreadpool 中是线程池中提供 一组独立的thread, 外部只需要 投递 任务即可，可能thread中的随机空闲线程执行
*/
namespace ZEGO
{

namespace CONNECTION
{
    using ZegoJobRunnable = std::function<void()>;

    class CThreadPoolImpl;
    class ZEGOCONNECTION_API ZegoConnectionThreadPool
    {
    public:
        static std::shared_ptr<ZegoConnectionThreadPool> GetInstance();
        virtual ~ZegoConnectionThreadPool();

        /**
        初始化模块

        @param maxCount最大的线程个数 默认3个
        @param ms  auto_exit_ms 单位ms 默认1min
        @return 返回错误码
        @notce
        */
        ZCError Init();

        /**
        反初始化模块

        @param
        @notce
        */
        void UnInit();

        /**
        是否已经初始化

        @notce
        */
        bool IsInited();

        /**
        异步投递一个任务到 default task.  该任务 可能是一个threadpool 中的一个随机空闲线程执行。  

        @param job 需要投递的任务
        @param job_type 当前任务如果是可能会阻塞当前线程，例如dns, 系统api 可能的阻塞调用，则填入JOB_BLOCK。若是非常重要的任务，且希望快速执行填入JOB_QUIC。
        @param priority 用于表示该任务的优先级，对于关键任务，可以设置更高优先级，避免任务排队耗时。
        @notce
        */
        void AnsycRunTaskInDefaultTask(ZegoJobRunnable &&job, JOB_RUNNABLE_TYPE job_type, JobPriorityType priority = JobPriorityType::Normal);

        /**
        同步投递一个任务到default task.  改任务 可能是一个threadpool 中的一个随机空闲线程执行。适用于当个任务的耗时操作类场景

        @param job 需要投递的任务
        @param waitMs 同步等待的时间 -1 默认无限等待 单位ms
        @param job_type 当前任务如果是可能会阻塞当前线程，例如dns, 系统api 可能的阻塞调用，则填入JOB_MAYBE_BLOCK。若只是需要异步执行下，可选择填入JOB_NO_BLOCK
        @param priority 用于表示该任务的优先级，对于关键任务，可以设置更高优先级，避免任务排队耗时。
        @notce
        */
        bool SyncRunTaskInDefaultTask(ZegoJobRunnable&& job, JOB_RUNNABLE_TYPE job_type, int waitMs = -1, JobPriorityType priority = JobPriorityType::Normal);

    private:
        ZegoConnectionThreadPool();

    private:
        std::shared_ptr<CThreadPoolImpl> thread_pool_impl_;
    };
}// CONNECTION
}// ZEGO


#endif /* zego_connection_thread_pool_hpp */
