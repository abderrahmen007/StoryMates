#pragma once

#include <stdint.h>
#include <functional>
#include <string>
#include <vector>

namespace zreporter
{
enum UploaderEC
{
    Success                     = 0,
    InnerError                  = 1,
    NetworkError                = 2,
    InvalidParam                = 3,
    ResponseError               = 4,
    FileNotExist                = 5,
    CreateZipFileFailed         = 6,
    kZBAddNewFileInZipFailed    = 7,
};

struct UploadRequest_t {
    /*  基本参数 */
    uint32_t    appid;
    std::string appsignature; /*  sign方式使用此参数鉴权 */
    std::string token;        /*  token方式使用此参数鉴权 */
    std::string product;      /*  product */
    std::string idname;       /*  user idname */
    std::string deviceid;     /*  device id */
    std::string url;          /*  请求url */
    std::string querykey;     /*  querykey */

    /*  日志文件信息 */
    std::string fileFullPath; /*  file utf8 full path */

    /*  可选参数 */
    uint32_t maxSpeed = 0; /*  限速, 单位 bytes/second, 0 表示不限制 */
};

struct UploadResponse_t {
    uint32_t    errorCode;
    uint32_t    detailErrorCode;
    std::string message;
};

struct QuerryRequest_t {
    /*  基本参数 */
    uint32_t    appid;
    std::string appsignature; /*  sign方式使用此参数鉴权 */
    std::string url;          /*  请求url */
    std::string querykey;     /*  querykey */
};

struct QuerryResponse_t {
    uint32_t    errorCode;
    uint32_t    detailErrorCode;
    std::string message;
    std::string url;
};

UploaderEC ZipLog(std::vector<std::string> logfileFullPathList, std::string zipfileFullPath);

using UploadCallback_t = std::function<void(const UploadResponse_t& response)>;
void UploadLog(const UploadRequest_t& request, const UploadCallback_t& callback);

using QuerryCallback_t = std::function<void(const QuerryResponse_t& response)>;
void QuerryLog(const QuerryRequest_t& request, const QuerryCallback_t& callback);

}  // namespace zreporter
