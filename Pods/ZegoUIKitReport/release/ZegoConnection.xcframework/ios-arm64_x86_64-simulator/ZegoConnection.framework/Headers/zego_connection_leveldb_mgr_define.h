#ifndef zego_connection_leveldb_mgr_define_hpp
#define zego_connection_leveldb_mgr_define_hpp

#include "kernel/include/zego_connection_define.hpp"
#include "kernel/modules/utility/ZegoLeveldb.hpp"

#include <functional>
#include <map>
#include <string>
#include <vector>

namespace ZEGO {
namespace CONNECTION {

using DBHandle = uint32_t;
#define DB_HANDLE_INVALID 0

/**
 * @brief Open leveldb callback
 * 
 * @param handle: 0-open fail, >0-open success
 */
using DBOpenCallback = std::function<void(DBHandle db_handle)>;

/**
 * @brief Read data callback
 * 
 * @param error 0-success, !0 fail
 * @param data valid when (error == 0) && (need_delete == false)
 * @param need_delete whether need delete key or not
 */
using DBReadDataCallback = std::function<void(ZCError error, const std::string &data)>;
using DBReadHeadDataCallback =
    std::function<void(ZCError error, const std::string &data, bool need_delete)>;

/**
 * @brief Save data callback
 * 
 *  @param error 0-success, !0 fail
 */
using DBSaveDataCallback = std::function<void(ZCError error)>;

/**
 * @brief Delete key callback
 * 
 *  @param error 0-success, !0 fail
 */
using DBDeleteKeyCallback = std::function<void(ZCError error)>;

/**
 * @brief Delete by keys callback
 * 
 * @param delete_size ApproximateSize of the delete operation
 */
using DBDeleteByKeysCallback = std::function<void(uint64_t delete_size)>;

/**
 * @brief Delete to callback
 * 
 * @param db_size ApproximateSize of db
 * @param delete_size ApproximateSize of the delete operation
 */
using DBDeleteToCallback = std::function<void(uint64_t db_size, uint64_t delete_size)>;

/**
 * @brief Load keys callback
 * 
 * @param keys result keys
 */
using DBLoadKeysCallback = std::function<void(const std::vector<std::string> &keys)>;

/**
 * @brief Load all keys callback
 * 
 * @param map key-value map
 */
using DBLoadAllKeysCallback = std::function<void(const std::map<std::string, std::string> &kvs)>;

/**
 * @brief Load data callback
 * 
 * @param kvs key-value map
 */
using DBLoadDataCallback = std::function<void(const std::vector<ZEGO::BASE::ZegoLeveldb::KV> &kvs)>;

/**
 * @brief Get size callback
 * 
 * @param size ApproximateSize of db
 */
using DBGetSizeCallback = std::function<void(uint64_t size)>;

/**
 * @brief Compact callback
 * 
 * @param size ApproximateSize of db
 */
using DBCompactCallback = std::function<void(uint64_t size)>;

/**
 * @brief Get compress ratio callback
 * 
 * @param ratio compress ratio
 */
using DBGetCompressRatioCallback = std::function<void(float ratio)>;

} // namespace CONNECTION
} // namespace ZEGO

#endif // zego_connection_leveldb_mgr_define_hpp
