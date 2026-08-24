#include <jni.h>
#include <string>
#include <fstream>
#include <sstream>
#include <vector>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/ptrace.h>
#include <sys/system_properties.h>
#include <dirent.h>
#include <algorithm>
#include <android/log.h>

#define LOG_TAG "NativeSecurity"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static std::string get_sys_prop(const char* key) {
    char value[PROP_VALUE_MAX] = {0};
    __system_property_get(key, value);
    return std::string(value);
}

static std::string to_lower(std::string str) {
    std::transform(str.begin(), str.end(), str.begin(), ::tolower);
    return str;
}

// 1. Check System Properties for Emulator indicators
static bool check_system_properties() {
    std::vector<std::string> keys = {
        "ro.hardware",
        "ro.kernel.qemu",
        "ro.product.model",
        "ro.product.device",
        "ro.product.manufacturer",
        "ro.product.brand",
        "ro.product.board",
        "ro.build.characteristics",
        "qemu.sf.fake_camera",
        "ro.boot.hardware"
    };

    for (const auto& key : keys) {
        std::string val = to_lower(get_sys_prop(key.c_str()));
        if (val.find("goldfish") != std::string::npos ||
            val.find("ranchu") != std::string::npos ||
            val.find("vbox86") != std::string::npos ||
            val.find("nox") != std::string::npos ||
            val.find("genymotion") != std::string::npos ||
            val.find("bluestacks") != std::string::npos ||
            val.find("andy") != std::string::npos ||
            val.find("tencent") != std::string::npos ||
            val.find("sdk_gphone") != std::string::npos ||
            val.find("google_sdk") != std::string::npos ||
            val.find("emulator") != std::string::npos) {
            return true;
        }
    }

    std::string qemu_val = get_sys_prop("ro.kernel.qemu");
    if (qemu_val == "1" || qemu_val == "true" || qemu_val == "yes") {
        return true;
    }

    return false;
}

// 2. Check /proc/cpuinfo for x86 / QEMU / hypervisor
static bool check_proc_cpuinfo() {
    std::ifstream cpuinfo("/proc/cpuinfo");
    if (!cpuinfo.is_open()) return false;

    std::string line;
    while (std::getline(cpuinfo, line)) {
        std::string lower = to_lower(line);
        if (lower.find("goldfish") != std::string::npos ||
            lower.find("qemu") != std::string::npos ||
            lower.find("hypervisor") != std::string::npos ||
            lower.find("bhyve") != std::string::npos ||
            lower.find("kvm") != std::string::npos) {
            return true;
        }
    }
    return false;
}

// 3. Check Translation Libraries & QEMU Pipe Files
static bool check_qemu_files_native() {
    const char* known_files[] = {
        "/dev/socket/qemud",
        "/dev/qemu_pipe",
        "/sys/qemu_trace",
        "/system/lib/libc_malloc_debug_qemu.so",
        "/system/bin/nox-prop",
        "/system/bin/ttVM-prop",
        "/drivers/vboxguest",
        "/sys/module/vboxguest",
        "/sys/module/qemu_trace",
        "/system/lib/libhoudini.so",
        "/system/lib64/libhoudini.so",
        "/system/lib/libndk_translation.so",
        "/system/lib64/libndk_translation.so"
    };

    for (const char* path : known_files) {
        if (access(path, F_OK) == 0) {
            return true;
        }
    }
    return false;
}

// 4. Check /proc/self/maps for Frida & Hooking frameworks
static bool check_proc_maps() {
    std::ifstream maps("/proc/self/maps");
    if (!maps.is_open()) return false;

    std::string line;
    while (std::getline(maps, line)) {
        std::string lower = to_lower(line);
        if (lower.find("frida") != std::string::npos ||
            lower.find("gadget") != std::string::npos ||
            lower.find("linjector") != std::string::npos ||
            lower.find("xposed") != std::string::npos ||
            lower.find("substrate") != std::string::npos) {
            return true;
        }
    }
    return false;
}

// 5. Check /proc/self/status for TracerPid
static bool check_tracer_pid() {
    std::ifstream status("/proc/self/status");
    if (!status.is_open()) return false;

    std::string line;
    while (std::getline(status, line)) {
        if (line.rfind("TracerPid:", 0) == 0) {
            std::string pid_str = line.substr(10);
            int pid = std::atoi(pid_str.c_str());
            if (pid > 0) return true;
        }
    }
    return false;
}

// 6. Check Frida threads in /proc/self/task/*/comm
static bool check_frida_threads() {
    DIR* dir = opendir("/proc/self/task");
    if (!dir) return false;

    struct dirent* entry;
    bool found = false;
    while ((entry = readdir(dir)) != nullptr) {
        if (entry->d_name[0] == '.') continue;

        std::string comm_path = std::string("/proc/self/task/") + entry->d_name + "/comm";
        std::ifstream comm_file(comm_path);
        if (comm_file.is_open()) {
            std::string name;
            std::getline(comm_file, name);
            std::string lower = to_lower(name);
            if (lower.find("gum-js-loop") != std::string::npos ||
                lower.find("gmain") != std::string::npos ||
                lower.find("gdbus") != std::string::npos ||
                lower.find("frida") != std::string::npos) {
                found = true;
                break;
            }
        }
    }
    closedir(dir);
    return found;
}

// 7. Check Frida default ports 27042 & 27043
static bool check_frida_port_native() {
    int ports[] = {27042, 27043};
    for (int port : ports) {
        int sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0) continue;

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

        // Set non-blocking timeout
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 100000; // 100ms
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char*)&tv, sizeof(tv));

        int res = connect(sock, (struct sockaddr*)&addr, sizeof(addr));
        close(sock);
        if (res == 0) return true;
    }
    return false;
}

// 8. Ptrace Anti-Attach Check
static bool check_ptrace_attach() {
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0) {
        return true; // Already traced/attached by debugger or frida
    }
    return false;
}

// Native JNI implementation functions
extern "C" JNIEXPORT jboolean JNICALL
Java_com_diskominfo_1prov_1bengkulu_e_1presensimobileprovinsibengkulu_MainActivity_checkEmulatorNativeC(
        JNIEnv* env, jobject thiz) {
    return (jboolean)(check_system_properties() || check_proc_cpuinfo() || check_qemu_files_native());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_diskominfo_1prov_1bengkulu_e_1presensimobileprovinsibengkulu_MainActivity_checkFridaNativeC(
        JNIEnv* env, jobject thiz) {
    return (jboolean)(check_proc_maps() || check_tracer_pid() || check_frida_threads() || check_frida_port_native() || check_ptrace_attach());
}
