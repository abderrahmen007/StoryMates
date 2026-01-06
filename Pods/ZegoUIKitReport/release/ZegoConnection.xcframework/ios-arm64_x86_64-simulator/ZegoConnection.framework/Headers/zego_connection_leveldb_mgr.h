#ifndef zego_connection_leveldb_mgr_hpp
#define zego_connection_leveldb_mgr_hpp

#include "kernel/modules/utility/ZegoLeveldb.hpp"
#include "zego_connection_leveldb_mgr_define.h"

#include <memory>

namespace ZEGO {
namespace CONNECTION {
class LeveldbMgrImpl;

class ZEGOCONNECTION_API ZegoConnectionLeveldbMgr {
  public:
    static std::shared_ptr<ZegoConnectionLeveldbMgr> CreateInstance(uint32_t handle);
    ZegoConnectionLeveldbMgr(uint32_t handle);
    ~ZegoConnectionLeveldbMgr();

  public:
    ZCError Init();
    void Uninit();

    void OpenDataBase(const std::string &path, const std::string &backup_path,
                      const ZEGO::BASE::LevelDBUserContext &user_context, DBOpenCallback callback);
    void CloseDataBase(DBHandle db_handle);
    void DeleteDataBase(DBHandle db_handle);

    void ReadData(DBHandle db_handle, const std::string &key, DBReadDataCallback callback);
    void ReadHeadData(DBHandle db_handle, const std::string &key, DBReadHeadDataCallback callback);
    void SaveData(DBHandle db_handle, const std::string &key, const std::string &data,
                  DBSaveDataCallback callback);
    void DeleteData(DBHandle db_handle, const std::string &key, DBDeleteKeyCallback callback);
    void DeleteByKeys(DBHandle db_handle, const std::vector<std::string> &keys,
                      DBDeleteByKeysCallback callback);
    void DeleteTo(DBHandle db_handle, uint64_t need_delete_to, DBDeleteToCallback callback);
    void LoadKeys(DBHandle db_handle, const std::string &key_start_with,
                  DBLoadKeysCallback callback);
    void LoadAllKeys(DBHandle db_handle, DBLoadAllKeysCallback callback);
    void LoadData(DBHandle db_handle, uint64_t need_bytes, DBLoadDataCallback callback);

    void GetSize(DBHandle db_handle, DBGetSizeCallback callback);
    void Compact(DBHandle db_handle, DBCompactCallback callback);
    void GetCompressRatio(DBHandle db_handle, DBGetCompressRatioCallback callback);

  private:
    std::shared_ptr<LeveldbMgrImpl> leveldb_mgr_impl_ = nullptr;
};
} // namespace CONNECTION
} // namespace ZEGO

#endif // zego_connection_leveldb_mgr_hpp