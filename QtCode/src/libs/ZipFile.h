#pragma once
#include <memory>
#include <mutex>
#include <string>
#include <vector>

struct zip;
typedef struct zip zip_t;

class ZipFile
{
public:
    ZipFile();
    ~ZipFile();

private:
    zip_t* zip_ = nullptr;
    std::shared_ptr<std::mutex> mutex_ = std::make_shared<std::mutex>();
    std::vector<std::string> buffer_;

public:
    bool opened() const { return zip_ != nullptr; }

    void openRead(const std::string& zip_filename);
    void openWrite(const std::string& zip_filename);
    void create(const std::string& zip_filename);
    void setPassword(const std::string& password) const;
    std::string readFile(const std::string& filename) const;
    void readFileToBuffer(const std::string& filename, std::vector<char>& content) const;
    void addData(const std::string& filename, const char* p, int size);
    void removeFile(const std::string& filename);
    std::vector<std::string> getFileNames() const;

private:
    static std::string u8name(const std::string& filename);
};
