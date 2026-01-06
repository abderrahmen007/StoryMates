#ifndef zego_connection_thread_pool_define_hpp
#define zego_connection_thread_pool_define_hpp

#include "zego_connection_define.hpp"

namespace ZEGO
{

namespace CONNECTION
{
    //线程池类型
    enum JOB_RUNNABLE_TYPE
    {
        JOB_BLOCK = 0, 
        JOB_NO_BLOCK = 1, 
        JOB_QUIC = 2,
    };

    //任务优先级
    enum class JobPriorityType
    {
        Key = 0,  //关键任务，优先找空闲线程执行，尽量避免任务排队
        Normal    //正常任务，尽量找工作线程执行，会存在任务排队现象
    };

#define BLOCK_POOL_KENRNEL_THREAD_COUNT 1
#define BLOCK_POOL_NORMAL_THREAD_COUNT 5

#define NO_BLOCK_POOL_KENRNEL_THREAD_COUNT 1
#define NO_BLOCK_POOL_NORMAL_THREAD_COUNT 0

#define QUIC_POOL_KENRNEL_THREAD_COUNT 1
#define QUIC_POOL_NORMAL_THREAD_COUNT 0

#define KERNEL_THREAD_AUTO_EXIT 5000
#define NORMAL_THREAD_AUTO_EXIT 60000

#define THREAD_BUSY_TASK_COUNT 3
#define THREAD_BUSY_TASK_COST 300

    inline const char* ZegoDescription(JOB_RUNNABLE_TYPE type)
    {
        switch (type) {
        case ZEGO::CONNECTION::JOB_BLOCK:
            return "JOB_BLOCK";
        case ZEGO::CONNECTION::JOB_NO_BLOCK:
            return "JOB_NO_BLOCK";
        case ZEGO::CONNECTION::JOB_QUIC:
            return "JOB_QUIC";
        default:
            break;
        }

        return "unkown";
    }

    inline const char* ZegoDescription(JobPriorityType type)
    {
        switch (type) {
            case ZEGO::CONNECTION::JobPriorityType::Key:
            return "Key";
            case ZEGO::CONNECTION::JobPriorityType::Normal:
            return "Normal";
        default:
            break;
        }

        return "unkown";
    }
    
}// CONNECTION
}// ZEGO


#endif /* zego_connection_thread_pool_define_hpp */
