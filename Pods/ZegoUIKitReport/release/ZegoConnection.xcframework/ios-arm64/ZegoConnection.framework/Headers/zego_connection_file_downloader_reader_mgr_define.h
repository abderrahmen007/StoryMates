#ifndef zego_connection_file_downloader_reader_mgr_define_h
#define zego_connection_file_downloader_reader_mgr_define_h

#include "zego_connection_define.hpp"

#include <functional>
#include <string>

namespace ZEGO {
namespace CONNECTION {

using OnDownloadResultDelegate = std::function<void(ZCError error_code, int status_code)>;
using OnDownloadProgressDelegate = std::function<void(
    uint64_t total_download, uint64_t already_download, uint64_t current_download)>;

class IFileDownloaderReader {
  public:
    virtual ~IFileDownloaderReader() {}

    virtual std::string GetContext() = 0;

    virtual ZCSeq Download(const std::string &url, const std::string &file_path, bool verify_cert,
                           uint64_t max_pending_length, bool cache_downloader_info,
                           OnDownloadResultDelegate result_delegate,
                           OnDownloadProgressDelegate progress_delegate) = 0;
    virtual void CancelDownload(ZCSeq seq) = 0;

    virtual int Open() = 0;
    virtual void Close() = 0;
    virtual int Read(void *buf, int size) = 0;
    virtual int Seek(int64_t pos, int seek_mode) = 0;
    virtual int64_t GetSize() = 0;
    virtual void AbortRead() = 0;
};
} // namespace CONNECTION
} // namespace ZEGO

#endif // zego_connection_file_downloader_reader_mgr_define.h