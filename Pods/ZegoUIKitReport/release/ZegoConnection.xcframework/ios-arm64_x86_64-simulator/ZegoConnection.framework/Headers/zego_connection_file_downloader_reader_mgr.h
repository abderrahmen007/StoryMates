#ifndef zego_connection_file_downloader_reader_mgr_h
#define zego_connection_file_downloader_reader_mgr_h

#include "kernel/modules/downloader/FileDownloaderReaderMgrImpl.h"
#include "zego_connection_file_downloader_reader_mgr_define.h"

namespace ZEGO {
namespace CONNECTION {
class FileDownloaderReaderMgrImpl;

class ZegoConnectionFileDownloaderReaderMgr {
  public:
    ZegoConnectionFileDownloaderReaderMgr(uint32_t handle);
    ~ZegoConnectionFileDownloaderReaderMgr();

  public:
    std::shared_ptr<IFileDownloaderReader> GetDownloaderReader(const std::string &context);
    void DestroyDownloaderReader(const std::string &context);

  private:
    std::shared_ptr<FileDownloaderReaderMgrImpl> mgr_impl_ = nullptr;
};
} // namespace CONNECTION
} // namespace ZEGO

#endif // zego_connection_file_downloader_reader_mgr.h