#include <queue>
#include <cstdint>
#include <cstddef>

constexpr std::size_t FIFO_DEPTH = 16;

static std::queue<uint8_t> fifo;

extern "C" {

    void fifo_init() {
        while (!fifo.empty())
            fifo.pop();
    }

    int is_empty() {
        return fifo.empty();
    }

    int is_full() {
        return fifo.size() == FIFO_DEPTH;
    }

    int push(int data) {
        if (is_full())
            return 0;

        fifo.push(static_cast<uint8_t>(data));
        return 1;
    }

    int pop() {
        if (is_empty())
            return -1;

        int data = fifo.front();
        fifo.pop();
        return data;
    }
}
