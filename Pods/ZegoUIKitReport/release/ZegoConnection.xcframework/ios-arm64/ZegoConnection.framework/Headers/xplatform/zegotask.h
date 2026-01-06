#if !defined(_ZEGOTASK_INC_)
#define _ZEGOTASK_INC_
#pragma once

#include "zegotypes.h"
#include "zegoexcept.h"
#include "zegothread.h"
#include "zegorefc.h"
#include "zegoepump.h"
#include "zegolock.h"
#include "zegoevent.h"
#include <atomic>

#ifdef __cplusplus

#define INVALID_TASKID		0

typedef uint32	task_id;

typedef enum etask_mode {
	etask_once		= 0,	/*excute once*/
	etask_repeat	= 1		/*excute until canceled*/
}etask_mode;

enum task_state_type
{
	task_state_dispatch = 1, //task dispatch start
	task_state_begin = 2, //task start begin
	task_state_end = 3, // task end
};

enum task_type
{
	task_type_normal = 1,
	task_type_delay = 2,
	task_type_timer = 3,
};

enum task_priority
{
	task_priority_low = 1,  //
	task_priority_normal = 2,
	task_priority_high = 3, //now can not used
};

struct task_observer_info
{
	uint32 taskid = 0;
	task_type type;
	task_state_type state;
	uint64 task_dispatch_time = 0; 
	uint64 task_begin_time = 0;
	uint64 task_end_time = 0;
};

//observe
class CZEGOTaskBase;
typedef void(*task_observer)(CZEGOTaskBase* pTaskBase, task_observer_info* observeInfo);

//thread idle
typedef void(*thread_idle_callback)(CZEGOTaskBase* pTaskBase);

/*使用必读
 * 1、对于CZEGOTaskBase创建出来的线程(不包含网络IO)，非IO线程都应该用此对象来创建。
 *     windows 平台:
 *         windows平台使用event 来实现唤醒机制
 *     android ios mac linux 嵌入式，使用pthread_cond_signal 条件变量来实现唤醒机制。
 *
 * 2、对于包含网络IO的线程，使用CZEGOTaskIO 线程来创建
 *     windows 平台
 *       网络模型： select 模型 
 *       线程唤醒机制：无，
         缺陷: 当存在fd 且无任务时最多，select 等待10ms. 也就是 会导致延迟10ms 执行投递的第一个任务
 *
 *     ios mac 平台:
 *        网络模型：poll 模型
 *        线程唤醒机制：使用pipe 唤醒
 *
 *     android linux 嵌入式平台
 *        网络模型：poll 模型
 *        线程唤醒机制：eventfd  使用eventfd
 *
 *
 */
class _ZEGO_CLS CZEGOTaskBase : public CRefCountSafe {
protected:
	enum ThreadType
	{
		base = 0,
		io   = 1,
	};

public:
	CZEGOTaskBase(const utf8* name, int sleepMS = 10, ethread_priority type = ethr_priority_normal, ThreadType thread_type = ThreadType::base);
	virtual ~ CZEGOTaskBase(void);
	
	/*push task to current thread*/
	static task_id	PushTask(const CScopeCall& task);
	static task_id	PushDelayTask(const CScopeCall& task, int64 period, etask_mode mode);
	
	/*push task to specified thread*/
	static task_id	PushTask(CZEGOTaskBase* target, const CScopeCall& task, task_priority priority = task_priority::task_priority_normal);
	static task_id	PushDelayTask(CZEGOTaskBase* target, const CScopeCall& task, int64 period /*in miliseconds*/, etask_mode mode);

	/*cancel task from current thread*/
	static boolean	CancelTask(task_id id);
	/*cancel task from specified thread*/
	static boolean	CancelTask(CZEGOTaskBase* target, task_id id);

	/*get the curretn run thread task */
	static CZEGOTaskBase* GetCurrentTask();

	/*add the observe to task */
	void SetTaskObserver(task_observer observer);
    
    const utf8*     GetName(void) const;
	
	boolean	Start(void);
	boolean	Stop(void);
	boolean IsStarted();
	
	inline operator hzegothread (void) {return m_hThread;}
	zegothread_id getthreadid(){return m_threadid;}

protected:
    virtual void    Eachloop(int32& t2wait);
    virtual void    OnStart(void);
    virtual void    OnStop(void);
    //when the thread no task will callback
    virtual void    OnIdle(void);
    //thread is idle no stop and task is empty return true
    boolean IsIdle();
	//the task is io thread
	boolean IsTaskIOThread();
	
private:
	virtual void Runloop(void);
	//thread function
	static void* ThreadProc(void* param);
	//observer
	static void Observer(CZEGOTaskBase* task, task_observer observer, task_id taskid, task_type type, task_state_type state, uint64 dispatch_time = 0, uint64 begin_time = 0, uint64 end_time = 0);

protected:
	//signal and notify active the thread if thread is have ios will overwride
    virtual void    Signal(void);
    virtual void    Waiting(int32 t2wait);

protected:
	ethread_priority	m_eType;
	zegothread_id		m_threadid;
	hzegothread			m_hThread;
	CZEGOLock			m_lock;
	void*				m_internal;
    int                 m_sleepMS;
	std::atomic<bool> m_bIsStop;
	ThreadType m_threadType = ThreadType::base;
	CZEGOEvent* m_signal = nullptr;          //use notify when have task in thread

	CZEGOLock			m_start_stop_lock;  //thread start and stop lock. 
};

class _ZEGO_CLS CZEGOTaskIO : public CZEGOTaskBase {
public:
	CZEGOTaskIO(const utf8* name, int sleepMS = 10, ethread_priority type = ethr_priority_normal);
	virtual ~ CZEGOTaskIO(void);
	
	static hzegofevent GetFevent(void);
	
protected:
	 void    Signal(void)override;
	 void    Waiting(int32 t2wait)override;
	 void    WaitingNotSignalFd(int32 t2wait);

private:
	hzegofevent	m_hFevent = nullptr;
};

typedef CZEGOTaskBase CZEGOTaskDefault;

#endif

#endif /* _ZEGOTASK_INC_ */
